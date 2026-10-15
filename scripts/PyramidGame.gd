class_name PyramidGame
extends Control

## Pyramid Solitaire Game Controller.
## Full implementation of standard Pyramid Solitaire: 28-card pyramid,
## pairing exposed cards summing to 13, King single discard, stock & waste,
## undo support, hint system, row clear bonuses, and drag-and-drop.

signal game_won

const PyramidCardScene = preload("res://scenes/pyramid_card.tscn")

# Layout Constants (Viewport 1280x720)
const CARD_SIZE := Vector2(92.0, 126.0)
const HORIZ_PITCH := 102.0
const VERT_PITCH := 46.0
const PYRAMID_TOP_Y := 72.0
const CENTER_X := 640.0

const STOCK_POS := Vector2(390.0, 520.0)
const WASTE_POS := Vector2(530.0, 520.0)
const DISCARD_POS := Vector2(770.0, 520.0)

# Game Piles
var pyramid_rows: Array[Array] = [[], [], [], [], [], [], []] # 7 rows (row 0: 1 ... row 6: 7)
var stock: Array[PyramidCard] = []
var waste: Array[PyramidCard] = []
var discard: Array[PyramidCard] = []
var all_cards: Array[PyramidCard] = []

# Interaction & Drag
var selected_card: PyramidCard = null
var _dragging_card: PyramidCard = null
var _drag_orig_pos: Vector2 = Vector2.ZERO
var _drag_mouse_offset: Vector2 = Vector2.ZERO

# Undo Stack
var undo_stack: Array[Dictionary] = []

# Game State
var score: int = 0
var moves_count: int = 0
var elapsed_seconds: float = 0.0
var is_timer_active: bool = false
var is_game_over: bool = false
var is_dealing: bool = false
var is_instant_mode: bool = false
var stock_passes_used: int = 0
var max_stock_passes: int = 3
var current_seed: int = 0

# UI Nodes
@onready var card_layer: Control = $CardLayer
@onready var slots_container: Control = $SlotsContainer
@onready var stock_slot: Panel = $SlotsContainer/StockSlot
@onready var stock_label: Label = $SlotsContainer/StockSlot/Label
@onready var stock_pass_label: Label = $SlotsContainer/StockSlot/PassLabel
@onready var waste_slot: Panel = $SlotsContainer/WasteSlot
@onready var discard_slot: Panel = $SlotsContainer/DiscardSlot
@onready var discard_count_label: Label = $SlotsContainer/DiscardSlot/CountLabel

# HUD UI
@onready var score_label: Label = $UICanvas/HUD/TopBar/HBox/ScorePill/ScoreLabel
@onready var moves_label: Label = $UICanvas/HUD/TopBar/HBox/MovesPill/MovesLabel
@onready var time_label: Label = $UICanvas/HUD/TopBar/HBox/TimePill/TimeLabel
@onready var passes_label: Label = $UICanvas/HUD/TopBar/HBox/PassesPill/PassesLabel
@onready var btn_undo: Button = $UICanvas/HUD/TopBar/HBox/BtnUndo
@onready var btn_hint: Button = $UICanvas/HUD/TopBar/HBox/BtnHint
@onready var btn_restart: Button = $UICanvas/HUD/TopBar/HBox/BtnRestart
@onready var btn_menu: Button = $UICanvas/HUD/TopBar/HBox/BtnMenu

# Toast & Dialogs
@onready var toast_panel: PanelContainer = $UICanvas/ToastPanel
@onready var toast_label: Label = $UICanvas/ToastPanel/ToastLabel

@onready var victory_dialog: Control = $UICanvas/VictoryDialog
@onready var victory_box: PanelContainer = $UICanvas/VictoryDialog/Panel
@onready var victory_title: Label = $UICanvas/VictoryDialog/Panel/VBox/Title
@onready var victory_details: Label = $UICanvas/VictoryDialog/Panel/VBox/Details
@onready var btn_victory_play_again: Button = $UICanvas/VictoryDialog/Panel/VBox/ButtonsHBox/BtnPlayAgain
@onready var btn_victory_menu: Button = $UICanvas/VictoryDialog/Panel/VBox/ButtonsHBox/BtnMenu

func _ready() -> void:
	max_stock_passes = GameSettings.pyramid_passes
	_setup_signals()
	start_new_game(false)

func _process(delta: float) -> void:
	if is_timer_active and not is_game_over:
		elapsed_seconds += delta
		time_label.text = _format_time(elapsed_seconds)

func _setup_signals() -> void:
	stock_slot.gui_input.connect(_on_stock_slot_gui_input)
	btn_undo.pressed.connect(_on_undo_clicked)
	btn_hint.pressed.connect(_on_hint_clicked)
	btn_restart.pressed.connect(func(): start_new_game(true))
	btn_menu.pressed.connect(_on_menu_clicked)

	btn_victory_play_again.pressed.connect(func(): start_new_game(false))
	btn_victory_menu.pressed.connect(_on_menu_clicked)

## Starts a new game. If reuse_seed is true, replays the same shuffle.
func start_new_game(reuse_seed: bool = false) -> void:
	is_game_over = false
	is_timer_active = false
	is_dealing = true
	score = 0
	moves_count = 0
	elapsed_seconds = 0.0
	stock_passes_used = 0
	max_stock_passes = GameSettings.pyramid_passes
	_deselect_card()
	undo_stack.clear()

	if victory_dialog != null:
		victory_dialog.visible = false
	if toast_panel != null:
		toast_panel.visible = false

	# Clean up previous cards
	for c in all_cards:
		if is_instance_valid(c):
			c.queue_free()
	all_cards.clear()
	for r in range(7):
		pyramid_rows[r].clear()
		pyramid_rows[r].resize(r + 1)
	stock.clear()
	waste.clear()
	discard.clear()

	if not reuse_seed or current_seed == 0:
		current_seed = randi()
	seed(current_seed)

	# Generate standard 52-card deck
	var deck: Array[Dictionary] = []
	for suit in ["Clubs", "Diamonds", "Hearts", "Spades"]:
		for rank in range(1, 14):
			deck.append({"suit": suit, "rank": rank})
	deck.shuffle()

	# Create cards
	for data in deck:
		var card: PyramidCard = PyramidCardScene.instantiate()
		card_layer.add_child(card)
		card.setup(data["suit"], data["rank"], false)
		card.position = STOCK_POS
		card.card_clicked.connect(_on_card_clicked)
		card.card_double_clicked.connect(_on_card_double_clicked)
		card.drag_started.connect(_on_card_drag_started)
		card.drag_updated.connect(_on_card_drag_updated)
		card.drag_ended.connect(_on_card_drag_ended)
		all_cards.append(card)

	_update_hud()

	if is_instant_mode:
		deal_instantly()
	else:
		_deal_cards_animated()

## Instantly deals cards without tween delay (ideal for automated tests).
func deal_instantly() -> void:
	var deck_idx: int = 0

	# Deal 28 cards to pyramid
	for r in range(7):
		for c in range(r + 1):
			var card: PyramidCard = all_cards[deck_idx]
			deck_idx += 1
			pyramid_rows[r][c] = card
			card.pile_type = "pyramid"
			card.row = r
			card.col = c
			card.position = _get_pyramid_card_pos(r, c)
			card.rotation = 0.0
			card.scale = Vector2.ONE
			card.z_index = r + 1
			card.set_face_up(true)

	# Remaining 24 cards to stock
	while deck_idx < all_cards.size():
		var card: PyramidCard = all_cards[deck_idx]
		deck_idx += 1
		stock.append(card)
		card.pile_type = "stock"
		card.row = -1
		card.col = -1
		card.position = STOCK_POS
		card.rotation = 0.0
		card.scale = Vector2.ONE
		card.z_index = stock.size()
		card.set_face_up(false)

	update_exposed_cards()
	_update_hud()
	is_dealing = false
	is_timer_active = true

## Animated deal sequence for player experience.
func _deal_cards_animated() -> void:
	var deck_idx: int = 0
	var deal_tween: Tween = create_tween()

	# Deal row by row into the pyramid
	for r in range(7):
		for c in range(r + 1):
			var card: PyramidCard = all_cards[deck_idx]
			deck_idx += 1
			pyramid_rows[r][c] = card
			card.pile_type = "pyramid"
			card.row = r
			card.col = c
			var target_pos := _get_pyramid_card_pos(r, c)
			var delay: float = (r * (r + 1) / 2.0 + c) * 0.035

			deal_tween.parallel().tween_callback(func():
				card.z_index = r + 1
				card.animate_to(target_pos, 0.0, Vector2.ONE, 0.22, r + 1)
				card.flip_to(true, 0.2)
			).set_delay(delay)

	# Rest to stock
	while deck_idx < all_cards.size():
		var card: PyramidCard = all_cards[deck_idx]
		deck_idx += 1
		stock.append(card)
		card.pile_type = "stock"
		card.row = -1
		card.col = -1
		card.position = STOCK_POS
		card.z_index = stock.size()
		card.set_face_up(false)

	deal_tween.chain().tween_callback(func():
		update_exposed_cards()
		_update_hud()
		is_dealing = false
		is_timer_active = true
	)

func _get_pyramid_card_pos(r: int, c: int) -> Vector2:
	var row_width: float = r * HORIZ_PITCH + CARD_SIZE.x
	var start_x: float = CENTER_X - (row_width * 0.5)
	var x: float = start_x + (c * HORIZ_PITCH)
	var y: float = PYRAMID_TOP_Y + (r * VERT_PITCH)
	return Vector2(x, y)

## Updates the exposed status of all cards in the pyramid and the top of the waste pile.
func update_exposed_cards() -> void:
	for r in range(7):
		for c in range(r + 1):
			var card: PyramidCard = pyramid_rows[r][c]
			if card != null and is_instance_valid(card):
				var exposed: bool
				if r == 6:
					exposed = true
				else:
					var child_left = pyramid_rows[r + 1][c]
					var child_right = pyramid_rows[r + 1][c + 1]
					exposed = (child_left == null and child_right == null)
				card.set_exposed(exposed)

	# Waste pile: only the topmost card is exposed and playable
	for i in range(waste.size()):
		var w_card: PyramidCard = waste[i]
		if is_instance_valid(w_card):
			var is_top: bool = (i == waste.size() - 1)
			w_card.set_exposed(is_top)
			w_card.mouse_filter = Control.MOUSE_FILTER_STOP if is_top else Control.MOUSE_FILTER_IGNORE

## Card click handler: Handles single-card King discards and 2-card 13-sum pairings.
func _on_card_clicked(card: PyramidCard) -> void:
	if is_game_over or is_dealing:
		return

	if not card.is_exposed or not card.is_face_up:
		_show_toast("That card is covered by cards below!")
		return

	# Kings (rank 13) are discarded solo with a single click
	if card.rank == 13:
		_discard_king(card)
		return

	# If nothing is selected, select this card
	if selected_card == null:
		_select_card(card)
		return

	# Clicking the same card deselects it
	if selected_card == card:
		_deselect_card()
		return

	# Pair check: sum to 13
	if selected_card.rank + card.rank == 13:
		_match_pair(selected_card, card)
	else:
		# Invalid pair: show friendly notice and switch selection to newly clicked card
		_show_toast("Must sum to 13 (%d + %d = %d)" % [selected_card.rank, card.rank, selected_card.rank + card.rank], 1.5)
		_select_card(card)

func _on_card_double_clicked(card: PyramidCard) -> void:
	_on_card_clicked(card)

func _select_card(card: PyramidCard) -> void:
	if selected_card != null and is_instance_valid(selected_card):
		selected_card.set_selected(false)
	selected_card = card
	selected_card.set_selected(true)

func _deselect_card() -> void:
	if selected_card != null and is_instance_valid(selected_card):
		selected_card.set_selected(false)
	selected_card = null

## Discards an exposed King (13) directly to the discard pile.
func _discard_king(card: PyramidCard) -> void:
	_deselect_card()
	moves_count += 1

	var undo_entry := {
		"type": "king",
		"card": card,
		"pile": card.pile_type,
		"row": card.row,
		"col": card.col,
		"pos": card.position,
		"rot": card.rotation,
		"z_index": card.z_index,
		"score_delta": 10,
		"row_cleared": -1
	}

	# Remove from source pile
	if card.pile_type == "pyramid":
		pyramid_rows[card.row][card.col] = null
	elif card.pile_type == "waste":
		waste.erase(card)

	# Check row cleared bonus
	var row_cleared_idx: int = -1
	if card.pile_type == "pyramid" and _is_row_fully_cleared(card.row):
		row_cleared_idx = card.row
		undo_entry["row_cleared"] = row_cleared_idx

	card.pile_type = "discard"
	discard.append(card)

	var rot: float = randf_range(-0.08, 0.08)
	card.animate_to(DISCARD_POS, rot, Vector2.ONE, 0.22, discard.size() + 20)

	var points: int = 10
	if row_cleared_idx >= 0:
		var bonus: int = _get_row_cleared_bonus(row_cleared_idx)
		points += bonus
		_show_toast("Row %d Cleared! +%d pts" % [row_cleared_idx + 1, bonus])
	_add_score(points)

	undo_stack.append(undo_entry)
	update_exposed_cards()
	_update_hud()
	_check_victory()

## Matches two exposed cards whose values sum to 13.
func _match_pair(card1: PyramidCard, card2: PyramidCard) -> void:
	_deselect_card()
	moves_count += 1

	var undo_entry := {
		"type": "pair",
		"card1": card1,
		"pile1": card1.pile_type,
		"row1": card1.row,
		"col1": card1.col,
		"pos1": card1.position,
		"rot1": card1.rotation,
		"z1": card1.z_index,
		"card2": card2,
		"pile2": card2.pile_type,
		"row2": card2.row,
		"col2": card2.col,
		"pos2": card2.position,
		"rot2": card2.rotation,
		"z2": card2.z_index,
		"score_delta": 10,
		"rows_cleared": []
	}

	# Remove card1
	if card1.pile_type == "pyramid":
		pyramid_rows[card1.row][card1.col] = null
	elif card1.pile_type == "waste":
		waste.erase(card1)

	# Remove card2
	if card2.pile_type == "pyramid":
		pyramid_rows[card2.row][card2.col] = null
	elif card2.pile_type == "waste":
		waste.erase(card2)

	# Check for cleared rows
	var rows_cleared: Array[int] = []
	for c in [card1, card2]:
		if c.pile_type == "pyramid" and c.row >= 0:
			if _is_row_fully_cleared(c.row) and not rows_cleared.has(c.row):
				rows_cleared.append(c.row)
	undo_entry["rows_cleared"] = rows_cleared

	card1.pile_type = "discard"
	card2.pile_type = "discard"
	discard.append(card1)
	discard.append(card2)

	var rot1: float = randf_range(-0.08, 0.08)
	var rot2: float = randf_range(-0.08, 0.08)
	card1.animate_to(DISCARD_POS, rot1, Vector2.ONE, 0.22, discard.size() + 20)
	card2.animate_to(DISCARD_POS, rot2, Vector2.ONE, 0.24, discard.size() + 21)

	var points: int = 10
	for r in rows_cleared:
		var bonus: int = _get_row_cleared_bonus(r)
		points += bonus
		_show_toast("Row %d Cleared! +%d pts" % [r + 1, bonus])
	_add_score(points)

	undo_stack.append(undo_entry)
	update_exposed_cards()
	_update_hud()
	_check_victory()

## Handles stock slot input: drawing a card or recycling waste.
func _on_stock_slot_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_stock_clicked()

func _on_stock_clicked() -> void:
	if is_game_over or is_dealing:
		return
	_deselect_card()

	if not stock.is_empty():
		# Draw 1 card from Stock to Waste
		var card: PyramidCard = stock.pop_back()
		moves_count += 1

		var undo_entry := {
			"type": "draw",
			"card": card,
			"prev_pos": card.position,
			"prev_face_up": card.is_face_up,
			"score_delta": 0
		}
		undo_stack.append(undo_entry)

		waste.append(card)
		card.pile_type = "waste"
		card.z_index = waste.size() + 5
		card.flip_to(true, 0.2)
		card.animate_to(WASTE_POS, 0.0, Vector2.ONE, 0.22, waste.size() + 5)

		update_exposed_cards()
		_update_hud()
	else:
		# Stock is empty: recycle waste back into stock
		if waste.is_empty():
			_show_toast("No cards in stock or waste!")
			return

		if stock_passes_used < max_stock_passes or max_stock_passes >= 900:
			stock_passes_used += 1
			moves_count += 1

			var recycled_cards: Array[PyramidCard] = []
			recycled_cards.append_array(waste)
			waste.clear()

			var undo_entry := {
				"type": "recycle",
				"cards": recycled_cards,
				"prev_pass": stock_passes_used - 1,
				"score_delta": 0
			}
			undo_stack.append(undo_entry)

			# Reverse order and return face down to stock
			recycled_cards.reverse()
			for i in range(recycled_cards.size()):
				var c: PyramidCard = recycled_cards[i]
				c.pile_type = "stock"
				stock.append(c)
				c.z_index = i + 1
				c.flip_to(false, 0.15)
				c.animate_to(STOCK_POS, 0.0, Vector2.ONE, 0.2, i + 1)

			var pass_str: String = "∞" if max_stock_passes >= 900 else str(max_stock_passes)
			_show_toast("Stock recycled! Pass %d/%s" % [stock_passes_used + 1, pass_str])
			update_exposed_cards()
			_update_hud()
		else:
			_show_toast("No more stock passes left!")

# Drag and Drop Implementation
func _on_card_drag_started(card: PyramidCard, global_pos: Vector2) -> void:
	if is_game_over or is_dealing or not card.is_exposed:
		card.cancel_drag()
		return
	_dragging_card = card
	_drag_orig_pos = card.position
	_drag_mouse_offset = card.global_position - global_pos
	card.z_index = 100

func _on_card_drag_updated(card: PyramidCard, global_pos: Vector2) -> void:
	if _dragging_card == card:
		card.global_position = global_pos + _drag_mouse_offset

func _on_card_drag_ended(card: PyramidCard, global_pos: Vector2) -> void:
	if _dragging_card != card:
		return
	_dragging_card = null

	# Check if King dropped onto discard slot
	if card.rank == 13 and discard_slot.get_global_rect().has_point(global_pos):
		_discard_king(card)
		return

	# Check if dropped onto another card that sums to 13
	var hit_card: PyramidCard = _find_exposed_card_under_pos(global_pos, card)
	if hit_card != null and hit_card.is_exposed and (card.rank + hit_card.rank == 13):
		_match_pair(card, hit_card)
		return

	# Not a valid drop: snap back to origin
	card.animate_to(_drag_orig_pos, card.base_rot, Vector2.ONE, 0.18, card.z_index)

func _find_exposed_card_under_pos(global_pos: Vector2, exclude_card: PyramidCard) -> PyramidCard:
	for i in range(card_layer.get_child_count() - 1, -1, -1):
		var child = card_layer.get_child(i) as PyramidCard
		if child != null and child != exclude_card and child.visible and child.is_exposed:
			if child.get_global_rect().has_point(global_pos):
				return child
	return null

## Undo the last action taken.
func _on_undo_clicked() -> void:
	if undo_stack.is_empty() or is_game_over or is_dealing:
		_show_toast("Nothing to undo!")
		return

	_deselect_card()
	var entry: Dictionary = undo_stack.pop_back()
	var action_type: String = entry.get("type", "")

	match action_type:
		"king":
			var c: PyramidCard = entry["card"]
			discard.erase(c)
			c.pile_type = entry["pile"]
			c.row = entry["row"]
			c.col = entry["col"]
			if entry["pile"] == "pyramid":
				pyramid_rows[entry["row"]][entry["col"]] = c
			elif entry["pile"] == "waste":
				waste.append(c)
			c.animate_to(entry["pos"], entry["rot"], Vector2.ONE, 0.2, entry["z_index"])
			_add_score(-entry["score_delta"])

		"pair":
			var c1: PyramidCard = entry["card1"]
			var c2: PyramidCard = entry["card2"]
			discard.erase(c1)
			discard.erase(c2)

			c1.pile_type = entry["pile1"]
			c1.row = entry["row1"]
			c1.col = entry["col1"]
			if entry["pile1"] == "pyramid":
				pyramid_rows[c1.row][c1.col] = c1
			elif entry["pile1"] == "waste":
				waste.append(c1)
			c1.animate_to(entry["pos1"], entry["rot1"], Vector2.ONE, 0.2, entry["z1"])

			c2.pile_type = entry["pile2"]
			c2.row = entry["row2"]
			c2.col = entry["col2"]
			if entry["pile2"] == "pyramid":
				pyramid_rows[c2.row][c2.col] = c2
			elif entry["pile2"] == "waste":
				waste.append(c2)
			c2.animate_to(entry["pos2"], entry["rot2"], Vector2.ONE, 0.2, entry["z2"])

			_add_score(-entry["score_delta"])

		"draw":
			var c: PyramidCard = entry["card"]
			waste.erase(c)
			stock.append(c)
			c.pile_type = "stock"
			c.row = -1
			c.col = -1
			c.flip_to(entry["prev_face_up"], 0.15)
			c.animate_to(entry["prev_pos"], 0.0, Vector2.ONE, 0.2, stock.size())

		"recycle":
			var cards: Array[PyramidCard] = entry["cards"]
			stock_passes_used = entry["prev_pass"]
			stock.clear()
			waste.clear()
			for i in range(cards.size()):
				var c: PyramidCard = cards[i]
				c.pile_type = "waste"
				waste.append(c)
				c.flip_to(true, 0.15)
				c.animate_to(WASTE_POS, 0.0, Vector2.ONE, 0.2, i + 5)

	moves_count = maxi(0, moves_count - 1)
	update_exposed_cards()
	_update_hud()
	_show_toast("Undone!", 1.0)

## Hint system: suggests a King or an exposed pair that sums to 13.
func _on_hint_clicked() -> void:
	if is_game_over or is_dealing:
		return

	# 1. Check for single King among exposed cards
	var exposed_cards: Array[PyramidCard] = _get_all_exposed_playable_cards()
	for c in exposed_cards:
		if c.rank == 13:
			c.set_hint(true)
			_show_toast("Hint: Discard King of %s solo!" % c.suit)
			return

	# 2. Check for matching pairs among exposed cards
	for i in range(exposed_cards.size()):
		for j in range(i + 1, exposed_cards.size()):
			var c1: PyramidCard = exposed_cards[i]
			var c2: PyramidCard = exposed_cards[j]
			if c1.rank + c2.rank == 13:
				c1.set_hint(true)
				c2.set_hint(true)
				_show_toast("Hint: Match %s and %s (13)!" % [c1.get_display_name(), c2.get_display_name()])
				return

	# 3. If no moves on board, suggest stock draw or recycle
	if not stock.is_empty():
		_show_toast("No matches on board. Draw from the Stock!")
	elif stock_passes_used < max_stock_passes or max_stock_passes >= 900:
		_show_toast("Stock is empty. Tap Stock to recycle!")
	else:
		_show_toast("No more moves available! Game Over or Undo.")

func _get_all_exposed_playable_cards() -> Array[PyramidCard]:
	var result: Array[PyramidCard] = []
	for r in range(7):
		for c in range(r + 1):
			var card: PyramidCard = pyramid_rows[r][c]
			if card != null and card.is_exposed:
				result.append(card)
	if not waste.is_empty():
		var top_w: PyramidCard = waste.back()
		if top_w != null and top_w.is_exposed:
			result.append(top_w)
	return result

func _is_row_fully_cleared(r: int) -> bool:
	for c in range(r + 1):
		if pyramid_rows[r][c] != null:
			return false
	return true

func _get_row_cleared_bonus(r: int) -> int:
	match r:
		6: return 15
		5: return 25
		4: return 35
		3: return 50
		2: return 75
		1: return 100
		0: return 250
		_: return 10

func _add_score(amount: int) -> void:
	score = maxi(0, score + amount)
	score_label.text = str(score)

func _check_victory() -> void:
	# Standard Pyramid Solitaire victory: all 28 cards of the pyramid cleared!
	var remaining_pyramid_cards: int = 0
	for r in range(7):
		for c in range(r + 1):
			if pyramid_rows[r][c] != null:
				remaining_pyramid_cards += 1

	if remaining_pyramid_cards == 0:
		_trigger_victory()

func _trigger_victory() -> void:
	is_game_over = true
	is_timer_active = false
	_add_score(500) # Full pyramid cleared bonus

	GameSettings.record_pyramid_game(score, true, moves_count, elapsed_seconds)

	if victory_dialog != null:
		victory_title.text = "PYRAMID CONQUERED!"
		var time_str: String = _format_time(elapsed_seconds)
		victory_details.text = "All 28 pyramid cards dismantled!\n\nScore: %d  |  Moves: %d  |  Time: %s\nBest Score: %d" % [
			score, moves_count, time_str, GameSettings.pyramid_best_score
		]
		victory_dialog.visible = true
		victory_dialog.modulate.a = 0.0
		victory_box.scale = Vector2(0.9, 0.9)
		var tween: Tween = create_tween().set_parallel(true)
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(victory_dialog, "modulate:a", 1.0, 0.25)
		tween.tween_property(victory_box, "scale", Vector2.ONE, 0.25)

	game_won.emit()

func _update_hud() -> void:
	if score_label != null:
		score_label.text = str(score)
	if moves_label != null:
		moves_label.text = str(moves_count)
	if passes_label != null:
		var pass_max_str: String = "∞" if max_stock_passes >= 900 else str(max_stock_passes)
		passes_label.text = "Pass: %d/%s" % [stock_passes_used + 1, pass_max_str]
	if discard_count_label != null:
		discard_count_label.text = "%d Cards" % discard.size()
	if stock_pass_label != null:
		stock_pass_label.text = "%d Left" % stock.size()

func _show_toast(msg: String, duration: float = 2.0) -> void:
	if toast_panel == null or toast_label == null:
		return
	toast_label.text = msg
	toast_panel.visible = true
	toast_panel.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(toast_panel, "modulate:a", 1.0, 0.15)
	tween.tween_interval(duration)
	tween.tween_property(toast_panel, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(func(): toast_panel.visible = false)

func _format_time(seconds: float) -> String:
	var total_sec: int = int(seconds)
	var mins: int = total_sec / 60
	var secs: int = total_sec % 60
	return "%02d:%02d" % [mins, secs]

func _on_menu_clicked() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
