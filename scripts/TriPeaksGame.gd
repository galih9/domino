class_name TriPeaksGame
extends Control

## Tri Peaks Solitaire Game Controller.
## Full implementation of classic Tri Peaks Solitaire:
## - 28-card tableau arranged across 3 overlapping peaks (4 rows: 3, 6, 9, 10 cards)
## - Uncovering mechanics: cards reveal and flip face up when their covering children are cleared
## - ±1 Rank matching onto Waste pile (with configurable Ace <-> King wrap-around)
## - Streak combo multiplier system (+10 * streak, streak toasts, peak clear bonuses)
## - Peak cleared bonuses (1st peak: +150, 2nd peak: +250, 3rd peak: +500)
## - Stock drawing & recycling options (1 pass, 3 passes, or unlimited)
## - Complete Undo history, intelligent Hint advisor, drag-and-drop & single-tap play
## - Full HUD, Victory dialog, Game Over detection, and instant test mode.

signal game_won

const TriPeaksCardScene = preload("res://scenes/tri_peaks_card.tscn")

# Viewport 1280x720 Layout Constants
const CARD_SIZE := Vector2(92.0, 126.0)
const HORIZ_PITCH := 106.0
const VERT_PITCH := 56.0
const ROW0_TOP_Y := 68.0

const STOCK_POS := Vector2(480.0, 480.0)
const WASTE_POS := Vector2(640.0, 480.0)

# Game Piles
# Rows: row 0 has 3 cards, row 1 has 6 cards, row 2 has 9 cards, row 3 has 10 cards
var tableau_rows: Array[Array] = [[], [], [], []]
var stock: Array[TriPeaksCard] = []
var waste: Array[TriPeaksCard] = []
var all_cards: Array[TriPeaksCard] = []

# Interaction & Drag
var _dragging_card: TriPeaksCard = null
var _drag_orig_pos: Vector2 = Vector2.ZERO
var _drag_mouse_offset: Vector2 = Vector2.ZERO

# Undo Stack
var undo_stack: Array[Dictionary] = []

# Game State
var score: int = 0
var moves_count: int = 0
var current_streak: int = 0
var max_streak: int = 0
var peaks_cleared: int = 0
var elapsed_seconds: float = 0.0
var is_timer_active: bool = false
var is_game_over: bool = false
var is_dealing: bool = false
var is_instant_mode: bool = false
var stock_passes_used: int = 0
var max_stock_passes: int = 1
var wrap_cards: bool = true
var current_seed: int = 0

# UI Nodes
@onready var card_layer: Control = $CardLayer
@onready var slots_container: Control = $SlotsContainer
@onready var stock_slot: Panel = $SlotsContainer/StockSlot
@onready var stock_label: Label = $SlotsContainer/StockSlot/Label
@onready var stock_count_label: Label = $SlotsContainer/StockSlot/CountLabel
@onready var waste_slot: Panel = $SlotsContainer/WasteSlot
@onready var waste_label: Label = $SlotsContainer/WasteSlot/Label

# HUD UI
@onready var score_label: Label = $UICanvas/HUD/TopBar/HBox/ScorePill/ScoreLabel
@onready var streak_label: Label = $UICanvas/HUD/TopBar/HBox/StreakPill/StreakLabel
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
	max_stock_passes = GameSettings.tripeaks_passes
	wrap_cards = GameSettings.tripeaks_wrap_cards
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

## Starts a fresh game. If reuse_seed is true, replays the same shuffle.
func start_new_game(reuse_seed: bool = false) -> void:
	is_game_over = false
	is_timer_active = false
	is_dealing = true
	score = 0
	moves_count = 0
	current_streak = 0
	max_streak = 0
	peaks_cleared = 0
	elapsed_seconds = 0.0
	stock_passes_used = 0
	max_stock_passes = GameSettings.tripeaks_passes
	wrap_cards = GameSettings.tripeaks_wrap_cards
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

	tableau_rows[0].clear()
	tableau_rows[0].resize(3)
	tableau_rows[1].clear()
	tableau_rows[1].resize(6)
	tableau_rows[2].clear()
	tableau_rows[2].resize(9)
	tableau_rows[3].clear()
	tableau_rows[3].resize(10)

	stock.clear()
	waste.clear()

	if not reuse_seed or current_seed == 0:
		current_seed = randi()
	seed(current_seed)

	# Generate standard 52-card deck
	var deck: Array[Dictionary] = []
	for suit in ["Clubs", "Diamonds", "Hearts", "Spades"]:
		for rank in range(1, 14):
			deck.append({"suit": suit, "rank": rank})
	deck.shuffle()

	# Create card nodes
	for data in deck:
		var card: TriPeaksCard = TriPeaksCardScene.instantiate()
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

## Instantly deals cards without animation delays (ideal for unit/automated tests).
func deal_instantly() -> void:
	var deck_idx: int = 0

	# 1. Deal 28 cards into the 4 tableau rows
	var row_sizes: Array[int] = [3, 6, 9, 10]
	for r in range(4):
		for c in range(row_sizes[r]):
			var card: TriPeaksCard = all_cards[deck_idx]
			deck_idx += 1
			tableau_rows[r][c] = card
			card.pile_type = "tableau"
			card.row = r
			card.col = c
			card.position = _get_tableau_card_pos(r, c)
			card.rotation = 0.0
			card.scale = Vector2.ONE
			card.z_index = r + 1
			# Row 3 cards start face up, rows 0-2 start face down
			var start_face_up: bool = (r == 3)
			card.set_face_up(start_face_up)
			if r == 0:
				card.peak_idx = c

	# 2. Deal remaining 24 cards to Stock
	while deck_idx < all_cards.size():
		var card: TriPeaksCard = all_cards[deck_idx]
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

	# 3. Immediately turn over 1 card from Stock to Waste pile
	if not stock.is_empty():
		var start_waste_card: TriPeaksCard = stock.pop_back()
		waste.append(start_waste_card)
		start_waste_card.pile_type = "waste"
		start_waste_card.position = WASTE_POS
		start_waste_card.set_face_up(true)
		start_waste_card.z_index = 10

	update_exposed_cards()
	_update_hud()
	is_dealing = false
	is_timer_active = true

## Animated deal sequence for players.
func _deal_cards_animated() -> void:
	var deck_idx: int = 0
	var deal_tween: Tween = create_tween()
	var row_sizes: Array[int] = [3, 6, 9, 10]
	var total_dealt: int = 0

	# Deal tableau cards row by row
	for r in range(4):
		for c in range(row_sizes[r]):
			var card: TriPeaksCard = all_cards[deck_idx]
			deck_idx += 1
			tableau_rows[r][c] = card
			card.pile_type = "tableau"
			card.row = r
			card.col = c
			if r == 0:
				card.peak_idx = c
			var target_pos := _get_tableau_card_pos(r, c)
			var delay: float = total_dealt * 0.028
			total_dealt += 1
			var is_row3: bool = (r == 3)

			deal_tween.parallel().tween_callback(func():
				card.z_index = r + 1
				card.animate_to(target_pos, 0.0, Vector2.ONE, 0.2, r + 1)
				if is_row3:
					card.flip_to(true, 0.18)
			).set_delay(delay)

	# Rest to stock
	while deck_idx < all_cards.size():
		var card: TriPeaksCard = all_cards[deck_idx]
		deck_idx += 1
		stock.append(card)
		card.pile_type = "stock"
		card.row = -1
		card.col = -1
		card.position = STOCK_POS
		card.z_index = stock.size()
		card.set_face_up(false)

	# Flip first waste card after tableau is dealt
	deal_tween.chain().tween_callback(func():
		if not stock.is_empty():
			var first_waste: TriPeaksCard = stock.pop_back()
			waste.append(first_waste)
			first_waste.pile_type = "waste"
			first_waste.z_index = 10
			first_waste.flip_to(true, 0.2)
			first_waste.animate_to(WASTE_POS, 0.0, Vector2.ONE, 0.22, 10)

		update_exposed_cards()
		_update_hud()
		is_dealing = false
		is_timer_active = true
	).set_delay(0.08)

## Calculates card position for the 3 peaks layout in 1280x720.
func _get_tableau_card_pos(r: int, c: int) -> Vector2:
	var total_base_width: float = 9.0 * HORIZ_PITCH + CARD_SIZE.x
	var start_x: float = (1280.0 - total_base_width) * 0.5

	var x: float = 0.0
	match r:
		3:
			x = start_x + (c * HORIZ_PITCH)
		2:
			x = start_x + ((c + 0.5) * HORIZ_PITCH)
		1:
			var col_offsets: Array[float] = [1.0, 2.0, 4.0, 5.0, 7.0, 8.0]
			x = start_x + (col_offsets[c] * HORIZ_PITCH)
		0:
			var peak_offsets: Array[float] = [1.5, 4.5, 7.5]
			x = start_x + (peak_offsets[c] * HORIZ_PITCH)

	var y: float = ROW0_TOP_Y + (r * VERT_PITCH)
	return Vector2(x, y)

## Checks if card (r, c) is currently covered by any remaining card in row r + 1.
func is_card_covered(r: int, c: int) -> bool:
	if r == 3:
		return false # Base row is never covered

	if r == 2:
		# (2, c) covered by (3, c) and (3, c + 1)
		var child_left = tableau_rows[3][c]
		var child_right = tableau_rows[3][c + 1]
		return (child_left != null or child_right != null)

	if r == 1:
		# (1, c) covered by two row 2 cards
		var base_c: int = (c / 2) * 3 + (c % 2)
		var child_left = tableau_rows[2][base_c]
		var child_right = tableau_rows[2][base_c + 1]
		return (child_left != null or child_right != null)

	if r == 0:
		# Peak (0, c) covered by (1, c * 2) and (1, c * 2 + 1)
		var child_left = tableau_rows[1][c * 2]
		var child_right = tableau_rows[1][c * 2 + 1]
		return (child_left != null or child_right != null)

	return false

## Updates exposed and face-up state for all tableau cards.
## Returns an array of cards that transitioned from covered to exposed.
func update_exposed_cards(animate_flips: bool = true) -> Array[TriPeaksCard]:
	var newly_exposed: Array[TriPeaksCard] = []

	for r in range(4):
		var row_size: int = tableau_rows[r].size()
		for c in range(row_size):
			var card: TriPeaksCard = tableau_rows[r][c]
			if card != null and is_instance_valid(card):
				var covered: bool = is_card_covered(r, c)
				var should_be_exposed: bool = not covered
				var was_exposed: bool = card.is_exposed

				card.set_exposed(should_be_exposed)

				if should_be_exposed:
					if not card.is_face_up:
						if animate_flips and not is_instant_mode:
							card.flip_to(true, 0.22)
						else:
							card.set_face_up(true)
					if not was_exposed:
						newly_exposed.append(card)

	# Waste pile: only topmost card is active
	for i in range(waste.size()):
		var w_card: TriPeaksCard = waste[i]
		if is_instance_valid(w_card):
			var is_top: bool = (i == waste.size() - 1)
			w_card.set_exposed(is_top)
			w_card.mouse_filter = Control.MOUSE_FILTER_STOP if is_top else Control.MOUSE_FILTER_IGNORE

	return newly_exposed

## Validates whether an exposed card can be legally played onto the current waste card.
func can_play_to_waste(card: TriPeaksCard) -> bool:
	if card == null or not is_instance_valid(card):
		return false
	if not card.is_exposed or not card.is_face_up:
		return false
	if waste.is_empty():
		return false

	var top_waste: TriPeaksCard = waste.back()
	var r1: int = card.rank
	var r2: int = top_waste.rank

	# Difference of exactly 1
	if abs(r1 - r2) == 1:
		return true

	# Wrap-around Ace (1) and King (13)
	if wrap_cards:
		if (r1 == 1 and r2 == 13) or (r1 == 13 and r2 == 1):
			return true

	return false

## Handles player card clicks: plays valid exposed tableau cards directly onto the waste pile.
func _on_card_clicked(card: TriPeaksCard) -> void:
	if is_game_over or is_dealing:
		return

	if card.pile_type == "stock":
		_on_stock_clicked()
		return

	if card.pile_type != "tableau":
		return

	if not card.is_exposed or not card.is_face_up:
		_show_toast("That card is covered by cards below!")
		return

	if can_play_to_waste(card):
		_play_card_to_waste(card)
	else:
		var top_name: String = waste.back().get_display_name() if not waste.is_empty() else "Empty"
		_show_toast("Card must be 1 higher or 1 lower than %s!" % top_name, 1.4)

func _on_card_double_clicked(card: TriPeaksCard) -> void:
	_on_card_clicked(card)

## Moves an exposed tableau card to the waste pile and processes scoring and uncovered cards.
func _play_card_to_waste(card: TriPeaksCard) -> void:
	moves_count += 1
	current_streak += 1
	if current_streak > max_streak:
		max_streak = current_streak

	var streak_points: int = 10 * current_streak
	var peak_bonus: int = 0
	var peak_idx_cleared: int = -1

	# Remove card from tableau row
	tableau_rows[card.row][card.col] = null

	# Check if this move cleared one of the three peaks (row 0)
	if card.row == 0:
		peak_idx_cleared = card.col
		peaks_cleared += 1
		match peaks_cleared:
			1: peak_bonus = 150
			2: peak_bonus = 250
			3: peak_bonus = 500
			_: peak_bonus = 150

	var total_points: int = streak_points + peak_bonus
	_add_score(total_points)

	# Show feedback toast for combos and peaks
	if peak_bonus > 0:
		var p_name: String = "Peak %d" % (peak_idx_cleared + 1)
		_show_toast("%s Cleared! +%d pts (Streak x%d)" % [p_name, total_points, current_streak], 2.0)
	elif current_streak >= 3:
		_show_toast("STREAK x%d! +%d pts" % [current_streak, total_points], 1.2)

	# Animate card to waste
	var prev_pos: Vector2 = card.position
	var prev_rot: float = card.rotation
	var prev_z: int = card.z_index

	card.pile_type = "waste"
	waste.append(card)
	var rot: float = randf_range(-0.06, 0.06)
	var target_z: int = waste.size() + 10
	card.animate_to(WASTE_POS, rot, Vector2.ONE, 0.22, target_z)

	# Uncover parent cards
	var newly_exposed: Array[TriPeaksCard] = update_exposed_cards(true)

	# Record for Undo
	var undo_entry := {
		"type": "tableau_to_waste",
		"card": card,
		"row": card.row,
		"col": card.col,
		"peak_idx": card.peak_idx,
		"prev_pos": prev_pos,
		"prev_rot": prev_rot,
		"prev_z": prev_z,
		"prev_streak": current_streak - 1,
		"score_delta": total_points,
		"peak_bonus": peak_bonus,
		"peak_idx_cleared": peak_idx_cleared,
		"uncovered_cards": newly_exposed
	}
	undo_stack.append(undo_entry)

	_update_hud()
	_check_victory()

## Handles stock slot input.
func _on_stock_slot_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_stock_clicked()

## Draws 1 card from Stock to Waste (resets streak), or recycles waste if stock is empty.
func _on_stock_clicked() -> void:
	if is_game_over or is_dealing:
		return

	if not stock.is_empty():
		var card: TriPeaksCard = stock.pop_back()
		moves_count += 1
		var prev_streak: int = current_streak
		current_streak = 0

		var undo_entry := {
			"type": "draw",
			"card": card,
			"prev_pos": card.position,
			"prev_streak": prev_streak,
			"score_delta": 0
		}
		undo_stack.append(undo_entry)

		waste.append(card)
		card.pile_type = "waste"
		card.z_index = waste.size() + 10
		card.flip_to(true, 0.2)
		card.animate_to(WASTE_POS, 0.0, Vector2.ONE, 0.22, waste.size() + 10)

		update_exposed_cards()
		_update_hud()
		_check_no_moves()
	else:
		# Stock is empty: recycle waste back into stock if passes remain
		if waste.size() <= 1:
			_show_toast("No cards left in stock to draw!")
			_check_no_moves()
			return

		if stock_passes_used < max_stock_passes or max_stock_passes >= 900:
			stock_passes_used += 1
			moves_count += 1
			var prev_streak: int = current_streak
			current_streak = 0

			# Keep top waste card as active target on the waste pile
			var top_waste_card: TriPeaksCard = waste.pop_back()

			var recycled_cards: Array[TriPeaksCard] = []
			recycled_cards.append_array(waste)
			waste.clear()
			waste.append(top_waste_card)

			var undo_entry := {
				"type": "recycle",
				"cards": recycled_cards,
				"prev_pass": stock_passes_used - 1,
				"prev_streak": prev_streak,
				"score_delta": 0
			}
			undo_stack.append(undo_entry)

			# Reverse waste cards back to stock face down
			recycled_cards.reverse()
			for i in range(recycled_cards.size()):
				var c: TriPeaksCard = recycled_cards[i]
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
			_show_toast("No more stock passes remaining!")
			_check_no_moves()

# Drag and Drop Implementation
func _on_card_drag_started(card: TriPeaksCard, global_pos: Vector2) -> void:
	if is_game_over or is_dealing or not card.is_exposed:
		card.cancel_drag()
		return
	_dragging_card = card
	_drag_orig_pos = card.position
	_drag_mouse_offset = card.global_position - global_pos
	card.z_index = 100

func _on_card_drag_updated(card: TriPeaksCard, global_pos: Vector2) -> void:
	if _dragging_card == card:
		card.global_position = global_pos + _drag_mouse_offset

func _on_card_drag_ended(card: TriPeaksCard, global_pos: Vector2) -> void:
	if _dragging_card != card:
		return
	_dragging_card = null

	# Check if dropped onto the waste slot or top waste card
	var over_waste: bool = waste_slot.get_global_rect().has_point(global_pos)
	if not over_waste and not waste.is_empty():
		over_waste = waste.back().get_global_rect().has_point(global_pos)

	if over_waste and can_play_to_waste(card):
		_play_card_to_waste(card)
		return

	# Return card to original position
	card.animate_to(_drag_orig_pos, card.base_rot, Vector2.ONE, 0.18, card.row + 1)

## Undoes the last player action and completely restores board state.
func _on_undo_clicked() -> void:
	if undo_stack.is_empty() or is_game_over or is_dealing:
		_show_toast("Nothing to undo!")
		return

	var entry: Dictionary = undo_stack.pop_back()
	var action_type: String = entry.get("type", "")

	match action_type:
		"tableau_to_waste":
			var c: TriPeaksCard = entry["card"]
			waste.erase(c)
			c.pile_type = "tableau"
			c.row = entry["row"]
			c.col = entry["col"]
			c.peak_idx = entry["peak_idx"]
			tableau_rows[c.row][c.col] = c

			if entry["peak_bonus"] > 0:
				peaks_cleared = maxi(0, peaks_cleared - 1)

			current_streak = entry["prev_streak"]
			_add_score(-entry["score_delta"])

			# Re-cover any cards that were exposed by this move
			var uncovered: Array = entry.get("uncovered_cards", [])
			for u_card in uncovered:
				if is_instance_valid(u_card):
					u_card.set_exposed(false)
					u_card.flip_to(false, 0.18)

			c.animate_to(entry["prev_pos"], entry["prev_rot"], Vector2.ONE, 0.2, entry["prev_z"])

		"draw":
			var c: TriPeaksCard = entry["card"]
			waste.erase(c)
			stock.append(c)
			c.pile_type = "stock"
			c.row = -1
			c.col = -1
			current_streak = entry["prev_streak"]
			c.flip_to(false, 0.15)
			c.animate_to(entry["prev_pos"], 0.0, Vector2.ONE, 0.2, stock.size())

		"recycle":
			var cards: Array[TriPeaksCard] = entry["cards"]
			stock_passes_used = entry["prev_pass"]
			current_streak = entry["prev_streak"]
			stock.clear()
			# Restore recycled cards to waste (beneath the top waste card)
			var top_card: TriPeaksCard = waste.pop_back()
			for i in range(cards.size()):
				var c: TriPeaksCard = cards[i]
				c.pile_type = "waste"
				waste.append(c)
				c.flip_to(true, 0.15)
				c.animate_to(WASTE_POS, 0.0, Vector2.ONE, 0.2, i + 5)
			if top_card != null:
				waste.append(top_card)

	moves_count = maxi(0, moves_count - 1)
	update_exposed_cards(false)
	_update_hud()
	_show_toast("Undone!", 1.0)

## Intelligent Hint system: scans for playable tableau cards or guides stock draws.
func _on_hint_clicked() -> void:
	if is_game_over or is_dealing:
		return

	# 1. Look for valid moves from exposed tableau cards
	var playable: Array[TriPeaksCard] = []
	for r in range(4):
		for c in range(tableau_rows[r].size()):
			var card: TriPeaksCard = tableau_rows[r][c]
			if card != null and card.is_exposed and can_play_to_waste(card):
				playable.append(card)

	if not playable.is_empty():
		var best_card: TriPeaksCard = playable[0]
		best_card.set_hint(true)
		var top_name: String = waste.back().get_display_name() if not waste.is_empty() else ""
		_show_toast("Hint: Play %s on %s!" % [best_card.get_display_name(), top_name], 2.2)
		return

	# 2. Check stock or recycle suggestions
	if not stock.is_empty():
		_show_toast("No matches on the peaks. Draw from the Stock!")
	elif stock_passes_used < max_stock_passes or max_stock_passes >= 900:
		_show_toast("Stock is empty. Tap Stock to recycle!")
	else:
		_show_toast("No more moves available! Game Over or Undo.")

func _check_no_moves() -> void:
	if is_game_over:
		return
	# Check if any tableau card is playable
	for r in range(4):
		for c in range(tableau_rows[r].size()):
			var card: TriPeaksCard = tableau_rows[r][c]
			if card != null and card.is_exposed and can_play_to_waste(card):
				return

	# If stock has cards or passes remain, game is not over
	if not stock.is_empty():
		return
	if stock_passes_used < max_stock_passes or max_stock_passes >= 900:
		return

	_show_toast("No moves remaining! Use Undo or restart.", 3.0)

## Victory condition: All 28 tableau cards cleared from the peaks.
func _check_victory() -> void:
	var remaining: int = 0
	for r in range(4):
		for c in range(tableau_rows[r].size()):
			if tableau_rows[r][c] != null:
				remaining += 1

	if remaining == 0:
		_trigger_victory()

func _trigger_victory() -> void:
	is_game_over = true
	is_timer_active = false
	_add_score(1000) # Grand board clear bonus

	GameSettings.record_tripeaks_game(score, true, moves_count, elapsed_seconds, max_streak)

	if victory_dialog != null:
		victory_title.text = "TRI PEAKS CONQUERED!"
		var time_str: String = _format_time(elapsed_seconds)
		victory_details.text = "All 28 cards dismantled across all 3 peaks!\n\nScore: %d  |  Streak: x%d  |  Moves: %d  |  Time: %s\nBest Score: %d" % [
			score, max_streak, moves_count, time_str, GameSettings.tripeaks_best_score
		]
		victory_dialog.visible = true
		victory_dialog.modulate.a = 0.0
		victory_box.scale = Vector2(0.9, 0.9)
		var tween: Tween = create_tween().set_parallel(true)
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(victory_dialog, "modulate:a", 1.0, 0.25)
		tween.tween_property(victory_box, "scale", Vector2.ONE, 0.25)

	game_won.emit()

func _add_score(amount: int) -> void:
	score = maxi(0, score + amount)
	if score_label != null:
		score_label.text = str(score)

func _update_hud() -> void:
	if score_label != null:
		score_label.text = str(score)
	if streak_label != null:
		streak_label.text = "x%d" % current_streak
	if moves_label != null:
		moves_label.text = str(moves_count)
	if passes_label != null:
		var pass_max_str: String = "∞" if max_stock_passes >= 900 else str(max_stock_passes)
		passes_label.text = "Pass: %d/%s" % [stock_passes_used + 1, pass_max_str]
	if stock_count_label != null:
		stock_count_label.text = "%d Left" % stock.size()

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
