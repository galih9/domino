class_name SolitaireGame
extends Control

## Klondike Solitaire (Poker Cards) Game Controller.
## Full implementation of standard Klondike card solitaire with Draw 1 / Draw 3,
## drag-and-drop, tap-to-move, hints, auto-finish, and full undo support.

signal game_won

const CardScene = preload("res://scenes/card.tscn")

# Layout Positions (Viewport 1280x720)
const CARD_SIZE := Vector2(100.0, 136.0)
const STOCK_POS := Vector2(140.0, 62.0)
const WASTE_POS := Vector2(290.0, 62.0)
const FOUNDATION_POSITIONS := [
	Vector2(590.0, 62.0),
	Vector2(740.0, 62.0),
	Vector2(890.0, 62.0),
	Vector2(1040.0, 62.0)
]
const TABLEAU_X := [140.0, 290.0, 440.0, 590.0, 740.0, 890.0, 1040.0]
const TABLEAU_Y := 220.0
const DY_HIDDEN := 18.0
const DY_VISIBLE := 28.0

# Game Piles
var all_cards: Array[SolitaireCard] = []
var stock: Array[SolitaireCard] = []
var waste: Array[SolitaireCard] = []
var foundations: Array[Array] = [[], [], [], []] # 4 foundation piles
var tableau: Array[Array] = [[], [], [], [], [], [], []] # 7 columns

# Drag State
var _dragging_cards: Array[SolitaireCard] = []
var _drag_orig_positions: Array[Vector2] = []
var _drag_card_offsets: Array[Vector2] = []
var _drag_mouse_offset: Vector2 = Vector2.ZERO
var _is_dragging: bool = false
var _drag_hovered_slot: Panel = null

# Undo Stack
var undo_stack: Array[Dictionary] = []

# Game State
var score: int = 0
var moves_count: int = 0
var elapsed_seconds: float = 0.0
var is_timer_active: bool = false
var is_game_over: bool = false
var draw_count: int = 1 # 1 or 3
var current_seed: int = 0
var is_auto_finishing: bool = false

# UI Nodes
@onready var card_layer: Control = $CardLayer
@onready var slots_container: Control = $SlotsContainer
@onready var stock_slot: Panel = $SlotsContainer/StockSlot
@onready var waste_slot: Panel = $SlotsContainer/WasteSlot
@onready var foundation_slots: Array[Panel] = [
	$SlotsContainer/Foundation0,
	$SlotsContainer/Foundation1,
	$SlotsContainer/Foundation2,
	$SlotsContainer/Foundation3
]
@onready var tableau_slots: Array[Panel] = [
	$SlotsContainer/Tableau0,
	$SlotsContainer/Tableau1,
	$SlotsContainer/Tableau2,
	$SlotsContainer/Tableau3,
	$SlotsContainer/Tableau4,
	$SlotsContainer/Tableau5,
	$SlotsContainer/Tableau6
]

# HUD UI
@onready var score_label: Label = $UICanvas/HUD/TopBar/HBox/ScorePill/ScoreLabel
@onready var moves_label: Label = $UICanvas/HUD/TopBar/HBox/MovesPill/MovesLabel
@onready var time_label: Label = $UICanvas/HUD/TopBar/HBox/TimePill/TimeLabel
@onready var draw_mode_btn: Button = $UICanvas/HUD/TopBar/HBox/BtnDrawMode
@onready var btn_undo: Button = $UICanvas/HUD/TopBar/HBox/BtnUndo
@onready var btn_hint: Button = $UICanvas/HUD/TopBar/HBox/BtnHint
@onready var btn_auto_finish: Button = $UICanvas/HUD/TopBar/HBox/BtnAutoFinish
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
	draw_count = GameSettings.solitaire_draw_count
	_setup_signals()
	_update_draw_mode_button_text()
	start_new_game(false)

func _process(delta: float) -> void:
	if is_timer_active and not is_game_over:
		elapsed_seconds += delta
		time_label.text = _format_time(elapsed_seconds)

func _setup_signals() -> void:
	stock_slot.gui_input.connect(_on_stock_clicked)
	btn_undo.pressed.connect(_on_undo_clicked)
	btn_hint.pressed.connect(_on_hint_clicked)
	btn_auto_finish.pressed.connect(_on_auto_finish_clicked)
	btn_restart.pressed.connect(func(): start_new_game(true))
	btn_menu.pressed.connect(_on_menu_clicked)
	draw_mode_btn.pressed.connect(_on_toggle_draw_mode)

	btn_victory_play_again.pressed.connect(func(): start_new_game(false))
	btn_victory_menu.pressed.connect(_on_menu_clicked)

	_setup_slot_hover()

	btn_auto_finish.visible = false
	victory_dialog.visible = false
	toast_panel.visible = false

func _setup_slot_hover() -> void:
	var slots: Array[Panel] = [stock_slot, waste_slot]
	slots.append_array(foundation_slots)
	slots.append_array(tableau_slots)
	for slot in slots:
		slot.mouse_entered.connect(_on_slot_mouse_entered.bind(slot))
		slot.mouse_exited.connect(_on_slot_mouse_exited.bind(slot))

func _on_slot_mouse_entered(slot: Panel) -> void:
	if _is_dragging:
		return
	_set_slot_glow(slot, true)

func _on_slot_mouse_exited(slot: Panel) -> void:
	if _is_dragging:
		return
	_set_slot_glow(slot, false)

func _set_slot_glow(slot: Panel, active: bool) -> void:
	if slot == null:
		return
	var glow: Panel = slot.get_node_or_null("HighlightGlow") as Panel
	if glow != null:
		glow.visible = active

func _on_menu_clicked() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_toggle_draw_mode() -> void:
	draw_count = 3 if draw_count == 1 else 1
	GameSettings.set_solitaire_draw_count(draw_count)
	_update_draw_mode_button_text()
	show_toast("Switched to Draw %d" % draw_count)

func _update_draw_mode_button_text() -> void:
	draw_mode_btn.text = "Draw %d" % draw_count

func start_new_game(reuse_seed: bool = false) -> void:
	victory_dialog.hide()
	btn_auto_finish.visible = false
	is_auto_finishing = false
	is_game_over = false
	_is_dragging = false
	_dragging_cards.clear()
	_drag_orig_positions.clear()
	_drag_card_offsets.clear()

	if _drag_hovered_slot != null:
		_set_slot_glow(_drag_hovered_slot, false)
		_drag_hovered_slot = null
	var all_slots: Array[Panel] = [stock_slot, waste_slot]
	all_slots.append_array(foundation_slots)
	all_slots.append_array(tableau_slots)
	for slot in all_slots:
		_set_slot_glow(slot, false)

	score = 0
	moves_count = 0
	elapsed_seconds = 0.0
	is_timer_active = false
	undo_stack.clear()

	_clear_all_cards()

	if not reuse_seed:
		current_seed = randi()
	seed(current_seed)

	_generate_deck()
	deal_game()

func _clear_all_cards() -> void:
	for c in all_cards:
		if is_instance_valid(c):
			if c.get_parent() == card_layer:
				card_layer.remove_child(c)
			c.queue_free()
	all_cards.clear()
	stock.clear()
	waste.clear()
	for f in foundations:
		f.clear()
	for col in tableau:
		col.clear()

func _generate_deck() -> void:
	all_cards.clear()
	var suits: Array[String] = ["Clubs", "Diamonds", "Hearts", "Spades"]

	for s in suits:
		for r in range(1, 14):
			var card: SolitaireCard = CardScene.instantiate()
			card_layer.add_child(card)
			card.setup(s, r, false)
			card.card_clicked.connect(_on_card_clicked)
			card.card_double_clicked.connect(_on_card_double_clicked)
			card.drag_started.connect(_on_card_drag_started)
			card.drag_updated.connect(_on_card_drag_updated)
			card.drag_ended.connect(_on_card_drag_ended)
			all_cards.append(card)

	all_cards.shuffle()

func deal_game() -> void:
	var deck: Array[SolitaireCard] = all_cards.duplicate()

	# Deal Tableau (7 columns)
	for col in range(7):
		for row in range(col + 1):
			var card: SolitaireCard = deck.pop_back()
			var is_top: bool = (row == col)
			card.pile_type = "tableau"
			card.pile_index = col
			card.set_face_up(is_top)
			tableau[col].append(card)

	# Remaining 24 cards go to Stock
	while not deck.is_empty():
		var card: SolitaireCard = deck.pop_back()
		card.pile_type = "stock"
		card.pile_index = 0
		card.set_face_up(false)
		stock.append(card)

	_layout_all_piles_instant()
	_restack_cards()
	_update_hud()
	is_timer_active = true

func deal_instantly() -> void:
	_layout_all_piles_instant()
	_restack_cards()
	_update_hud()

func _restack_cards() -> void:
	var order: Array[SolitaireCard] = []

	# 1. Stock pile (bottom to top)
	for i in range(stock.size()):
		var c: SolitaireCard = stock[i]
		order.append(c)
		c.mouse_filter = Control.MOUSE_FILTER_STOP if (i == stock.size() - 1) else Control.MOUSE_FILTER_IGNORE

	# 2. Waste pile (bottom to top)
	for i in range(waste.size()):
		var c: SolitaireCard = waste[i]
		order.append(c)
		c.mouse_filter = Control.MOUSE_FILTER_STOP if (i == waste.size() - 1) else Control.MOUSE_FILTER_IGNORE

	# 3. Foundation piles (bottom to top of each foundation)
	for f_idx in range(4):
		var f: Array = foundations[f_idx]
		for i in range(f.size()):
			var c: SolitaireCard = f[i]
			order.append(c)
			c.mouse_filter = Control.MOUSE_FILTER_STOP if (i == f.size() - 1) else Control.MOUSE_FILTER_IGNORE

	# 4. Tableau columns (from row 0 to row N-1)
	for col_idx in range(7):
		var col: Array = tableau[col_idx]
		for i in range(col.size()):
			var c: SolitaireCard = col[i]
			order.append(c)
			if c.is_face_up:
				c.mouse_filter = Control.MOUSE_FILTER_STOP
			else:
				c.mouse_filter = Control.MOUSE_FILTER_STOP if (i == col.size() - 1) else Control.MOUSE_FILTER_IGNORE

	# 5. Dragging cards (always on top of everything)
	for c in _dragging_cards:
		if not order.has(c):
			order.append(c)
		c.mouse_filter = Control.MOUSE_FILTER_STOP

	# Reorder children in card_layer and assign sequential z_index
	for i in range(order.size()):
		var c: SolitaireCard = order[i]
		card_layer.move_child(c, i)
		if _dragging_cards.has(c):
			var drag_idx: int = _dragging_cards.find(c)
			c.z_index = 100 + drag_idx
		elif c.is_moving:
			c.z_index = 60 + i
		else:
			c.z_index = i

func _layout_all_piles_instant() -> void:
	for c in all_cards:
		c.stop_movement()

	# Stock
	for i in range(stock.size()):
		var c: SolitaireCard = stock[i]
		c.position = STOCK_POS
		c.rotation = 0.0
		c.scale = Vector2.ONE
		c.z_index = i
		c.base_pos = STOCK_POS
		c.set_face_up(false)

	# Waste
	for i in range(waste.size()):
		var c: SolitaireCard = waste[i]
		c.position = WASTE_POS
		c.rotation = 0.0
		c.scale = Vector2.ONE
		c.z_index = 10 + i
		c.base_pos = WASTE_POS
		c.set_face_up(true)

	# Foundations
	for f_idx in range(4):
		var f: Array = foundations[f_idx]
		for i in range(f.size()):
			var c: SolitaireCard = f[i]
			var pos: Vector2 = FOUNDATION_POSITIONS[f_idx]
			c.position = pos
			c.rotation = 0.0
			c.scale = Vector2.ONE
			c.z_index = 20 + i
			c.base_pos = pos
			c.set_face_up(true)

	# Tableau
	for col in range(7):
		_layout_tableau_column(col)

func _layout_tableau_column(col: int) -> void:
	var column: Array = tableau[col]
	var y: float = TABLEAU_Y
	var x: float = TABLEAU_X[col]

	# Dynamic vertical spacing compression for deep columns
	var dy_vis: float = DY_VISIBLE
	var dy_hid: float = DY_HIDDEN
	if column.size() > 10:
		var factor: float = clampf(10.0 / float(column.size()), 0.55, 1.0)
		dy_vis *= factor
		dy_hid *= factor

	for i in range(column.size()):
		var c: SolitaireCard = column[i]
		var target_pos := Vector2(x, y)
		c.position = target_pos
		c.rotation = 0.0
		c.scale = Vector2.ONE
		c.z_index = 30 + i
		c.base_pos = target_pos
		y += dy_vis if c.is_face_up else dy_hid

func _on_stock_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_draw_from_stock()

func _draw_from_stock() -> void:
	if is_auto_finishing:
		return

	if stock.is_empty():
		if waste.is_empty():
			return
		# Recycle waste back into stock
		undo_stack.append({
			"type": "recycle",
			"count": waste.size(),
			"prev_score": score
		})

		score = maxi(0, score - 20)
		moves_count += 1

		while not waste.is_empty():
			var c: SolitaireCard = waste.pop_back()
			c.pile_type = "stock"
			c.pile_index = 0
			c.set_face_up(false)
			stock.append(c)

		_layout_all_piles_instant()
		_restack_cards()
		_update_hud()
		return

	# Draw cards from stock to waste
	var drawn: Array[SolitaireCard] = []
	var count_to_draw: int = mini(draw_count, stock.size())

	for i in range(count_to_draw):
		var card: SolitaireCard = stock.pop_back()
		card.pile_type = "waste"
		card.pile_index = 0
		card.set_face_up(true)
		card.base_pos = WASTE_POS
		waste.append(card)
		drawn.append(card)

	moves_count += 1
	undo_stack.append({
		"type": "draw",
		"cards": drawn,
		"prev_score": score
	})

	# Animate drawn cards to waste
	for i in range(drawn.size()):
		var c: SolitaireCard = drawn[i]
		var tween: Tween = c.animate_to(WASTE_POS, 0.0, Vector2.ONE, 0.18)
		if i == drawn.size() - 1:
			tween.chain().tween_callback(func():
				_restack_cards()
			)

	_restack_cards()
	_update_hud()
	_check_auto_finish_available()

func _on_card_clicked(card: SolitaireCard) -> void:
	if is_auto_finishing:
		return

	if card.pile_type == "stock":
		_draw_from_stock()
		return

	# If face-down card in tableau is at the top of its column: flip it face up!
	if card.pile_type == "tableau" and not card.is_face_up:
		var col: Array = tableau[card.pile_index]
		if col.back() == card:
			card.flip_to(true, 0.2)
			score += 5
			moves_count += 1
			undo_stack.append({
				"type": "flip",
				"card": card,
				"prev_score": score - 5
			})
			_restack_cards()
			_update_hud()
			_check_auto_finish_available()
		return

	# Single click face-up card: attempt auto move to Foundation or best Tableau spot
	_attempt_auto_move(card)

func _on_card_double_clicked(card: SolitaireCard) -> void:
	if is_auto_finishing or not card.is_face_up:
		return
	_attempt_move_to_foundation(card)

func _attempt_auto_move(card: SolitaireCard) -> bool:
	# 1. Try Foundation first
	if _attempt_move_to_foundation(card):
		return true

	# 2. Try Tableau move
	if card.pile_type == "waste" or card.pile_type == "tableau":
		return _attempt_move_to_tableau(card)

	return false

func _attempt_move_to_foundation(card: SolitaireCard) -> bool:
	# Can only move single card to foundation (must be top card of its pile)
	if card.pile_type == "waste":
		if waste.is_empty() or waste.back() != card:
			return false
	elif card.pile_type == "tableau":
		if tableau[card.pile_index].is_empty() or tableau[card.pile_index].back() != card:
			return false
	elif card.pile_type == "foundation":
		return false

	for f_idx in range(4):
		if _can_card_go_to_foundation(card, f_idx):
			_execute_move_to_foundation(card, f_idx)
			return true
	return false

func _can_card_go_to_foundation(card: SolitaireCard, f_idx: int) -> bool:
	var f: Array = foundations[f_idx]
	if f.is_empty():
		return card.rank == 1 # Ace starts foundation
	var top_card: SolitaireCard = f.back()
	return top_card.suit == card.suit and card.rank == top_card.rank + 1

func _execute_move_to_foundation(card: SolitaireCard, f_idx: int) -> void:
	var source_type: String = card.pile_type
	var source_idx: int = card.pile_index
	var flipped_prev: SolitaireCard = null

	if source_type == "waste":
		waste.pop_back()
	elif source_type == "tableau":
		tableau[source_idx].pop_back()
		if not tableau[source_idx].is_empty() and not tableau[source_idx].back().is_face_up:
			flipped_prev = tableau[source_idx].back()
			flipped_prev.set_face_up(true)
			score += 5

	card.pile_type = "foundation"
	card.pile_index = f_idx
	foundations[f_idx].append(card)

	score += 10
	moves_count += 1

	undo_stack.append({
		"type": "move",
		"cards": [card],
		"from_type": source_type,
		"from_index": source_idx,
		"to_type": "foundation",
		"to_index": f_idx,
		"flipped_prev": flipped_prev,
		"prev_score": score - (15 if flipped_prev else 10)
	})

	var target_pos: Vector2 = FOUNDATION_POSITIONS[f_idx]
	var tween: Tween = card.animate_to(target_pos, 0.0, Vector2.ONE, 0.2)
	tween.chain().tween_callback(func():
		_restack_cards()
	)

	if source_type == "tableau":
		_layout_tableau_column(source_idx)

	_restack_cards()
	_update_hud()
	_check_auto_finish_available()
	_check_victory()

func _attempt_move_to_tableau(card: SolitaireCard) -> bool:
	var moving_cards: Array[SolitaireCard] = []
	var from_col: int = -1

	if card.pile_type == "waste":
		if waste.is_empty() or waste.back() != card:
			return false
		moving_cards.append(card)
	elif card.pile_type == "tableau":
		from_col = card.pile_index
		var col: Array = tableau[from_col]
		var idx: int = col.find(card)
		if idx < 0:
			return false
		for i in range(idx, col.size()):
			moving_cards.append(col[i])

	if moving_cards.is_empty():
		return false

	# Check each tableau column for valid placement
	for target_col in range(7):
		if target_col == from_col:
			continue
		if _can_cards_go_to_tableau(moving_cards[0], target_col):
			_execute_move_to_tableau(moving_cards, card.pile_type, from_col, target_col)
			return true

	return false

func _can_cards_go_to_tableau(bottom_card: SolitaireCard, target_col: int) -> bool:
	var col: Array = tableau[target_col]
	if col.is_empty():
		return bottom_card.rank == 13 # Only King can go to empty column
	var top_card: SolitaireCard = col.back()
	return top_card.is_face_up and top_card.is_red() != bottom_card.is_red() and top_card.rank == bottom_card.rank + 1

func _execute_move_to_tableau(moving_cards: Array[SolitaireCard], from_type: String, from_col: int, to_col: int) -> void:
	var flipped_prev: SolitaireCard = null

	if from_type == "waste":
		waste.pop_back()
		score += 5
	elif from_type == "tableau":
		for c in moving_cards:
			tableau[from_col].erase(c)
		if not tableau[from_col].is_empty() and not tableau[from_col].back().is_face_up:
			flipped_prev = tableau[from_col].back()
			flipped_prev.set_face_up(true)
			score += 5
	elif from_type == "foundation":
		foundations[from_col].erase(moving_cards[0])
		score = maxi(0, score - 15)

	for c in moving_cards:
		c.pile_type = "tableau"
		c.pile_index = to_col
		tableau[to_col].append(c)

	moves_count += 1
	undo_stack.append({
		"type": "move",
		"cards": moving_cards,
		"from_type": from_type,
		"from_index": from_col,
		"to_type": "tableau",
		"to_index": to_col,
		"flipped_prev": flipped_prev,
		"prev_score": score
	})

	_layout_tableau_column(to_col)
	if from_type == "tableau":
		_layout_tableau_column(from_col)

	_restack_cards()
	_update_hud()
	_check_auto_finish_available()

# Drag & Drop Support
func _on_card_drag_started(card: SolitaireCard, mouse_pos: Vector2) -> void:
	if is_auto_finishing or not card.is_face_up:
		card.cancel_drag()
		return

	_dragging_cards.clear()
	_drag_orig_positions.clear()
	_drag_card_offsets.clear()

	if card.pile_type == "waste":
		if waste.is_empty() or waste.back() != card:
			card.cancel_drag()
			return
		_dragging_cards.append(card)
	elif card.pile_type == "foundation":
		if foundations[card.pile_index].is_empty() or foundations[card.pile_index].back() != card:
			card.cancel_drag()
			return
		_dragging_cards.append(card)
	elif card.pile_type == "tableau":
		var col: Array = tableau[card.pile_index]
		var idx: int = col.find(card)
		if idx < 0:
			card.cancel_drag()
			return
		for i in range(idx, col.size()):
			if not col[i].is_face_up:
				card.cancel_drag()
				_dragging_cards.clear()
				return
			_dragging_cards.append(col[i])

	if _dragging_cards.is_empty():
		card.cancel_drag()
		return

	_is_dragging = true
	_drag_mouse_offset = card.global_position - mouse_pos
	if _drag_hovered_slot != null:
		_set_slot_glow(_drag_hovered_slot, false)
		_drag_hovered_slot = null

	var lead_base_pos: Vector2 = card.base_pos
	for i in range(_dragging_cards.size()):
		var c: SolitaireCard = _dragging_cards[i]
		if c._move_tween and c._move_tween.is_valid():
			c._move_tween.kill()
			c.is_moving = false
		_drag_orig_positions.append(c.base_pos)
		_drag_card_offsets.append(c.base_pos - lead_base_pos)
		card_layer.move_child(c, -1)
		c.z_index = 100 + i
		c.set_highlight(true)

func _on_card_drag_updated(card: SolitaireCard, mouse_pos: Vector2) -> void:
	if not _is_dragging or _dragging_cards.is_empty():
		return

	var lead_target: Vector2 = mouse_pos + _drag_mouse_offset
	for i in range(_dragging_cards.size()):
		_dragging_cards[i].position = lead_target + _drag_card_offsets[i]

	_update_drag_slot_hover(mouse_pos, _dragging_cards[0])

func _update_drag_slot_hover(mouse_pos: Vector2, lead_card: SolitaireCard) -> void:
	var target_slot: Panel = null
	var drop_rect := Rect2(lead_card.position, CARD_SIZE)

	# 1. Foundation slots
	if _dragging_cards.size() == 1:
		for f_idx in range(4):
			var f_rect := Rect2(FOUNDATION_POSITIONS[f_idx], CARD_SIZE)
			if drop_rect.intersects(f_rect) or f_rect.has_point(mouse_pos):
				target_slot = foundation_slots[f_idx]
				break

	# 2. Tableau slots
	if target_slot == null:
		for col in range(7):
			if lead_card.pile_type == "tableau" and col == lead_card.pile_index:
				continue
			var col_x: float = TABLEAU_X[col]
			var col_rect: Rect2
			if tableau[col].is_empty():
				col_rect = Rect2(col_x, TABLEAU_Y, CARD_SIZE.x, CARD_SIZE.y)
			else:
				var top_c: SolitaireCard = tableau[col].back()
				col_rect = Rect2(col_x, TABLEAU_Y, CARD_SIZE.x, maxf(CARD_SIZE.y, top_c.position.y + CARD_SIZE.y - TABLEAU_Y))

			var mouse_in_col: bool = (mouse_pos.x >= col_x - 15.0 and mouse_pos.x <= col_x + CARD_SIZE.x + 15.0 and mouse_pos.y >= TABLEAU_Y - 30.0)
			if mouse_in_col or drop_rect.intersects(col_rect):
				target_slot = tableau_slots[col]
				break

	if target_slot != _drag_hovered_slot:
		if _drag_hovered_slot != null:
			_set_slot_glow(_drag_hovered_slot, false)
		_drag_hovered_slot = target_slot
		if _drag_hovered_slot != null:
			_set_slot_glow(_drag_hovered_slot, true)

func _on_card_drag_ended(card: SolitaireCard, mouse_pos: Vector2) -> void:
	if not _is_dragging or _dragging_cards.is_empty():
		_is_dragging = false
		_dragging_cards.clear()
		return
	_is_dragging = false

	if _drag_hovered_slot != null:
		_set_slot_glow(_drag_hovered_slot, false)
		_drag_hovered_slot = null

	for c in _dragging_cards:
		c.set_highlight(false)

	var lead_card: SolitaireCard = _dragging_cards[0]
	var drop_rect := Rect2(lead_card.position, CARD_SIZE)

	# 1. Try dropping on Foundation (only if single card)
	if _dragging_cards.size() == 1:
		for f_idx in range(4):
			var f_rect := Rect2(FOUNDATION_POSITIONS[f_idx], CARD_SIZE)
			if drop_rect.intersects(f_rect) or f_rect.has_point(mouse_pos):
				if _can_card_go_to_foundation(lead_card, f_idx):
					_execute_move_to_foundation(lead_card, f_idx)
					_dragging_cards.clear()
					return

	# 2. Try dropping on Tableau
	var best_col: int = -1
	var best_score: float = -1.0

	for col in range(7):
		if lead_card.pile_type == "tableau" and col == lead_card.pile_index:
			continue
		if not _can_cards_go_to_tableau(lead_card, col):
			continue

		var col_x: float = TABLEAU_X[col]
		var col_rect: Rect2
		if tableau[col].is_empty():
			col_rect = Rect2(col_x, TABLEAU_Y, CARD_SIZE.x, CARD_SIZE.y)
		else:
			var top_c: SolitaireCard = tableau[col].back()
			col_rect = Rect2(col_x, TABLEAU_Y, CARD_SIZE.x, maxf(CARD_SIZE.y, top_c.position.y + CARD_SIZE.y - TABLEAU_Y))

		var mouse_in_col: bool = (mouse_pos.x >= col_x - 15.0 and mouse_pos.x <= col_x + CARD_SIZE.x + 15.0 and mouse_pos.y >= TABLEAU_Y - 30.0)
		var intersects: bool = drop_rect.intersects(col_rect)

		if mouse_in_col or intersects:
			var overlap_area: float = 0.0
			var inter = drop_rect.intersection(col_rect)
			if inter.has_area():
				overlap_area = inter.size.x * inter.size.y
			var score: float = overlap_area + (100000.0 if mouse_in_col else 0.0)
			score -= absf((lead_card.position.x + CARD_SIZE.x * 0.5) - (col_x + CARD_SIZE.x * 0.5)) * 10.0
			if score > best_score:
				best_score = score
				best_col = col

	if best_col != -1:
		_execute_move_to_tableau(_dragging_cards, lead_card.pile_type, lead_card.pile_index, best_col)
		_dragging_cards.clear()
		return

	# Snap back on invalid drop
	var count: int = _dragging_cards.size()
	for i in range(count):
		var c: SolitaireCard = _dragging_cards[i]
		var orig_pos: Vector2 = _drag_orig_positions[i]
		var tween: Tween = c.animate_to(orig_pos, 0.0, Vector2.ONE, 0.18)
		if i == count - 1:
			tween.chain().tween_callback(func():
				_restack_cards()
			)
	_dragging_cards.clear()

# Undo Functionality
func _on_undo_clicked() -> void:
	if undo_stack.is_empty() or is_auto_finishing:
		return

	var rec: Dictionary = undo_stack.pop_back()
	var act: String = rec["type"]

	match act:
		"draw":
			var cards: Array = rec["cards"]
			for c in cards:
				waste.erase(c)
				c.pile_type = "stock"
				c.pile_index = 0
				c.set_face_up(false)
				stock.append(c)
			score = rec["prev_score"]
			_layout_all_piles_instant()
			show_toast("Draw Undone")

		"recycle":
			while not stock.is_empty():
				var c: SolitaireCard = stock.pop_back()
				c.pile_type = "waste"
				c.pile_index = 0
				c.set_face_up(true)
				waste.append(c)
			score = rec["prev_score"]
			_layout_all_piles_instant()
			show_toast("Recycle Undone")

		"flip":
			var c: SolitaireCard = rec["card"]
			c.set_face_up(false)
			score = rec["prev_score"]
			_update_hud()
			show_toast("Flip Undone")

		"move":
			var cards: Array = rec["cards"]
			var from_type: String = rec["from_type"]
			var from_idx: int = rec["from_index"]
			var to_type: String = rec["to_type"]
			var to_idx: int = rec["to_index"]
			var flipped_prev: SolitaireCard = rec["flipped_prev"]

			# Unflip previous card if it was flipped by this move
			if flipped_prev != null:
				flipped_prev.set_face_up(false)

			# Remove from destination
			if to_type == "foundation":
				foundations[to_idx].erase(cards[0])
			elif to_type == "tableau":
				for c in cards:
					tableau[to_idx].erase(c)

			# Restore to source
			if from_type == "waste":
				cards[0].pile_type = "waste"
				cards[0].pile_index = 0
				waste.append(cards[0])
			elif from_type == "foundation":
				cards[0].pile_type = "foundation"
				cards[0].pile_index = from_idx
				foundations[from_idx].append(cards[0])
			elif from_type == "tableau":
				for c in cards:
					c.pile_type = "tableau"
					c.pile_index = from_idx
					tableau[from_idx].append(c)

			score = rec["prev_score"]
			_layout_all_piles_instant()
			show_toast("Move Undone")

	_restack_cards()
	_update_hud()
	_check_auto_finish_available()

# Hints
func _on_hint_clicked() -> void:
	if is_auto_finishing:
		return

	# 1. Foundation move from Tableau or Waste
	if not waste.is_empty():
		for f_idx in range(4):
			if _can_card_go_to_foundation(waste.back(), f_idx):
				_highlight_hint(waste.back(), foundation_slots[f_idx])
				show_toast("Hint: Move %s to Foundation" % waste.back().get_display_name())
				return

	for col in range(7):
		if not tableau[col].is_empty():
			var top_c: SolitaireCard = tableau[col].back()
			if top_c.is_face_up:
				for f_idx in range(4):
					if _can_card_go_to_foundation(top_c, f_idx):
						_highlight_hint(top_c, foundation_slots[f_idx])
						show_toast("Hint: Move %s to Foundation" % top_c.get_display_name())
						return

	# 2. Move in Tableau that reveals a hidden card
	for col in range(7):
		if tableau[col].size() > 1:
			var idx: int = -1
			for i in range(tableau[col].size()):
				if tableau[col][i].is_face_up:
					idx = i
					break
			if idx > 0: # Has hidden card underneath
				var c: SolitaireCard = tableau[col][idx]
				for target_col in range(7):
					if target_col != col and _can_cards_go_to_tableau(c, target_col):
						_highlight_hint(c, tableau_slots[target_col])
						show_toast("Hint: Move %s to Column %d" % [c.get_display_name(), target_col + 1])
						return

	# 3. Waste card to Tableau
	if not waste.is_empty():
		for target_col in range(7):
			if _can_cards_go_to_tableau(waste.back(), target_col):
				_highlight_hint(waste.back(), tableau_slots[target_col])
				show_toast("Hint: Move %s to Column %d" % [waste.back().get_display_name(), target_col + 1])
				return

	# 4. Draw from stock
	if not stock.is_empty():
		_highlight_hint_slot(stock_slot)
		show_toast("Hint: Draw from Stock")
		return
	elif not waste.is_empty():
		_highlight_hint_slot(stock_slot)
		show_toast("Hint: Recycle Waste to Stock")
		return

	show_toast("No obvious moves available")

func _highlight_hint(card: SolitaireCard, slot: Panel) -> void:
	card.set_highlight(true)
	_set_slot_glow(slot, true)
	var t: Tween = create_tween()
	t.tween_interval(1.2)
	t.tween_callback(func():
		card.set_highlight(false)
		_set_slot_glow(slot, false)
	)

func _highlight_hint_slot(slot: Panel) -> void:
	_set_slot_glow(slot, true)
	var t: Tween = create_tween()
	t.tween_interval(1.2)
	t.tween_callback(func():
		_set_slot_glow(slot, false)
	)

# Auto-Finish
func _check_auto_finish_available() -> void:
	if is_game_over:
		btn_auto_finish.visible = false
		return

	if stock.is_empty() and waste.is_empty():
		var all_revealed: bool = true
		for col in tableau:
			for c in col:
				if not c.is_face_up:
					all_revealed = false
					break
		if all_revealed and not _is_all_on_foundations():
			btn_auto_finish.visible = true
			return

	btn_auto_finish.visible = false

func _is_all_on_foundations() -> bool:
	for f in foundations:
		if f.size() < 13:
			return false
	return true

func _on_auto_finish_clicked() -> void:
	if is_auto_finishing:
		return
	is_auto_finishing = true
	btn_auto_finish.visible = false

	while not _is_all_on_foundations():
		var moved_any: bool = false
		for col in range(7):
			if not tableau[col].is_empty():
				var c: SolitaireCard = tableau[col].back()
				for f_idx in range(4):
					if _can_card_go_to_foundation(c, f_idx):
						_execute_move_to_foundation(c, f_idx)
						moved_any = true
						await get_tree().create_timer(0.08).timeout
						break
				if moved_any:
					break
		if not moved_any:
			break

	is_auto_finishing = false
	_check_victory()

func _check_victory() -> void:
	if _is_all_on_foundations():
		_trigger_victory()

func _trigger_victory() -> void:
	is_game_over = true
	is_timer_active = false

	GameSettings.record_solitaire_game(score, true, moves_count, elapsed_seconds)
	game_won.emit()

	victory_title.text = "SOLITAIRE VICTORY!"
	victory_details.text = "Final Score: %d  |  Moves: %d  |  Time: %s" % [
		score, moves_count, _format_time(elapsed_seconds)
	]

	victory_dialog.visible = true
	victory_dialog.modulate.a = 0.0
	victory_box.scale = Vector2(0.92, 0.92)
	var tween: Tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(victory_dialog, "modulate:a", 1.0, 0.25)
	tween.tween_property(victory_box, "scale", Vector2.ONE, 0.25)

func _update_hud() -> void:
	score_label.text = "%d pts" % score
	moves_label.text = "Moves: %d" % moves_count
	time_label.text = _format_time(elapsed_seconds)
	btn_undo.disabled = undo_stack.is_empty()

func _format_time(sec: float) -> String:
	var s: int = int(sec)
	var m: int = s / 60
	s = s % 60
	return "%02d:%02d" % [m, s]

func show_toast(msg: String) -> void:
	toast_label.text = msg
	toast_panel.visible = true
	toast_panel.modulate.a = 0.0

	var tween: Tween = create_tween()
	tween.tween_property(toast_panel, "modulate:a", 1.0, 0.15)
	tween.tween_interval(1.1)
	tween.tween_property(toast_panel, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): toast_panel.visible = false)
