class_name SolitaireGame
extends Control

## Klondike Solitaire (Poker Cards) Game Controller.
## Full implementation of standard Klondike card solitaire with Draw 1 / Draw 3,
## drag-and-drop, tap-to-move, hints, auto-finish, and full undo support.
## NOTE FOR DEVELOPERS: NEVER ADD EMOJIS TO UI STRINGS/LABELS!
## Web export does not bundle emoji fonts and shows ugly binary hex boxes instead.

signal game_won

const CardScene = preload("res://scenes/card.tscn")
const SolitaireFxBurst = preload("res://scripts/SolitaireFxBurst.gd")

# Verified solvable Klondike seeds under standard rules
const WINNABLE_SEEDS: Array[int] = [
	117, 134, 168, 185, 202, 236, 253, 270, 338, 355,
	372, 389, 423, 491, 508, 525, 559, 576, 593, 661,
	678, 695, 712, 746, 763, 780, 797, 814, 865, 882,
	899, 916, 933, 1052, 1069, 1154, 1205, 1222, 1273, 1307,
	1375, 1409, 1426, 1443, 1477, 1494, 1511, 1545, 1579, 1596,
	1613, 1630, 1647, 1664, 1681, 1749, 1766, 1800, 1817, 1885,
	1919, 1936, 1970, 1987, 2004, 2021, 2055, 2072, 2140, 2157,
	2208, 2225, 2242, 2276, 2293, 2327, 2361, 2395, 2531, 2548,
	2616, 2667, 2735, 2769, 2803, 2820, 2837, 2888, 2905, 2922,
	2956, 2973, 3007, 3075, 3109, 3126, 3143, 3194, 3245, 3262
]

# Layout Positions (Viewport 1280x720)
const CARD_SIZE := Vector2(100.0, 136.0)
const CARD_WIDTH: float = 100.0
const CARD_HEIGHT: float = 136.0
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
var difficulty: String = "Standard" # "Standard" or "Easy"
var deal_type: String = "Winnable" # "Winnable" or "Random"
var current_seed: int = 0
var is_auto_finishing: bool = false
var _last_hint_index: int = -1

# UI Nodes
@onready var camera: Camera2D = $Camera2D
@onready var card_layer: Control = $CardLayer
@onready var fx_layer: Control = $FxLayer
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
@onready var score_pill: PanelContainer = $UICanvas/HUD/TopBar/HBox/ScorePill
@onready var score_label: Label = $UICanvas/HUD/TopBar/HBox/ScorePill/ScoreLabel
@onready var moves_label: Label = $UICanvas/HUD/TopBar/HBox/MovesPill/MovesLabel
@onready var time_label: Label = $UICanvas/HUD/TopBar/HBox/TimePill/TimeLabel
@onready var draw_mode_btn: Button = $UICanvas/HUD/TopBar/HBox/BtnDrawMode
@onready var btn_difficulty: Button = $UICanvas/HUD/TopBar/HBox/BtnDifficulty
@onready var btn_deal_type: Button = $UICanvas/HUD/TopBar/HBox/BtnDealType
@onready var btn_undo: Button = $UICanvas/HUD/TopBar/HBox/BtnUndo
@onready var btn_hint: Button = $UICanvas/HUD/TopBar/HBox/BtnHint
@onready var btn_wand: Button = $UICanvas/HUD/TopBar/HBox/BtnWand
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
	difficulty = GameSettings.solitaire_difficulty
	deal_type = GameSettings.solitaire_deal_type
	_setup_signals()
	_update_draw_mode_button_text()
	_update_difficulty_button_text()
	_update_deal_type_button_text()
	start_new_game(false)

func _process(delta: float) -> void:
	if is_timer_active and not is_game_over:
		elapsed_seconds += delta
		time_label.text = _format_time(elapsed_seconds)

	if is_auto_finishing and camera != null:
		var t: float = Time.get_ticks_msec() / 1000.0
		var shake_intensity: float = 2.0
		camera.offset = Vector2(
			sin(t * 37.0) * shake_intensity + cos(t * 53.0) * (shake_intensity * 0.4),
			cos(t * 41.0) * shake_intensity + sin(t * 61.0) * (shake_intensity * 0.4)
		)

func _setup_signals() -> void:
	stock_slot.gui_input.connect(_on_stock_clicked)
	btn_undo.pressed.connect(_on_undo_clicked)
	btn_hint.pressed.connect(_on_hint_clicked)
	btn_wand.pressed.connect(_on_wand_clicked)
	btn_auto_finish.pressed.connect(_on_auto_finish_clicked)
	btn_restart.pressed.connect(func(): start_new_game(true))
	btn_menu.pressed.connect(_on_menu_clicked)
	draw_mode_btn.pressed.connect(_on_toggle_draw_mode)
	btn_difficulty.pressed.connect(_on_toggle_difficulty)
	btn_deal_type.pressed.connect(_on_toggle_deal_type)

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

func _on_toggle_difficulty() -> void:
	difficulty = "Easy" if difficulty == "Standard" else "Standard"
	GameSettings.set_solitaire_difficulty(difficulty)
	_update_difficulty_button_text()
	show_toast("Difficulty: %s" % difficulty)

func _update_difficulty_button_text() -> void:
	if btn_difficulty != null:
		btn_difficulty.text = difficulty
	for col_idx in range(7):
		if col_idx < tableau_slots.size() and tableau_slots[col_idx] != null:
			var emblem: Label = tableau_slots[col_idx].get_node_or_null("Emblem") as Label
			if emblem != null:
				emblem.text = "ANY" if difficulty == "Easy" else "K"

func _on_toggle_deal_type() -> void:
	deal_type = "Random" if deal_type == "Winnable" else "Winnable"
	GameSettings.set_solitaire_deal_type(deal_type)
	_update_deal_type_button_text()
	show_toast("Deal Type: %s" % deal_type)

func _update_deal_type_button_text() -> void:
	if btn_deal_type != null:
		btn_deal_type.text = deal_type

func start_new_game(reuse_seed: bool = false) -> void:
	victory_dialog.hide()
	btn_auto_finish.visible = false
	is_auto_finishing = false
	_last_hint_index = -1
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
	if camera != null:
		camera.offset = Vector2.ZERO
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
		if deal_type == "Winnable":
			current_seed = WINNABLE_SEEDS[randi() % WINNABLE_SEEDS.size()]
		else:
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

func _is_any_card_moving() -> bool:
	for c in all_cards:
		if is_instance_valid(c) and c.is_card_moving():
			return true
	return false

func _restack_cards() -> void:
	var order: Array[SolitaireCard] = []

	# 1. Stock pile (bottom to top)
	for i in range(stock.size()):
		var c: SolitaireCard = stock[i]
		if not order.has(c):
			order.append(c)
		c.mouse_filter = Control.MOUSE_FILTER_STOP if (i == stock.size() - 1) else Control.MOUSE_FILTER_IGNORE

	# 2. Waste pile (bottom to top)
	for i in range(waste.size()):
		var c: SolitaireCard = waste[i]
		if not order.has(c):
			order.append(c)
		c.mouse_filter = Control.MOUSE_FILTER_STOP if (i == waste.size() - 1) else Control.MOUSE_FILTER_IGNORE

	# 3. Foundation piles (bottom to top of each foundation)
	for f_idx in range(4):
		var f: Array = foundations[f_idx]
		for i in range(f.size()):
			var c: SolitaireCard = f[i]
			if not order.has(c):
				order.append(c)
			c.mouse_filter = Control.MOUSE_FILTER_STOP if (i == f.size() - 1) else Control.MOUSE_FILTER_IGNORE

	# 4. Tableau columns (from row 0 to row N-1)
	for col_idx in range(7):
		var col: Array = tableau[col_idx]
		for i in range(col.size()):
			var c: SolitaireCard = col[i]
			if not order.has(c):
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

	# 6. Ensure any stray cards are included in order
	for c in all_cards:
		if is_instance_valid(c) and not order.has(c):
			order.append(c)

	# Reorder children in card_layer and assign sequential z_index
	for i in range(order.size()):
		var c: SolitaireCard = order[i]
		if c.get_parent() == card_layer and i < card_layer.get_child_count():
			card_layer.move_child(c, i)
		if _dragging_cards.has(c):
			var drag_idx: int = _dragging_cards.find(c)
			c.z_index = 200 + drag_idx
		elif c.is_moving:
			c.z_index = 100 + i
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
		c.base_pos = STOCK_POS
		c.set_face_up(false)

	# Waste
	for i in range(waste.size()):
		var c: SolitaireCard = waste[i]
		c.position = WASTE_POS
		c.rotation = 0.0
		c.scale = Vector2.ONE
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
			c.base_pos = pos
			c.set_face_up(true)

	# Tableau
	for col in range(7):
		_layout_tableau_column(col)

func _layout_tableau_column(col: int, animate_cards: Array = [], duration: float = 0.2) -> void:
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

	var moving_count: int = 0
	for c in animate_cards:
		if column.has(c):
			moving_count += 1
	var remaining_moves: Array = [moving_count]

	for i in range(column.size()):
		var c: SolitaireCard = column[i]
		var target_pos := Vector2(x, y)
		c.rotation = 0.0
		c.scale = Vector2.ONE
		c.base_pos = target_pos

		if animate_cards.has(c):
			var flight_idx: int = animate_cards.find(c)
			c.z_index = 100 + flight_idx
			var tween: Tween = c.animate_to(target_pos, 0.0, Vector2.ONE, duration)
			tween.chain().tween_callback(func():
				remaining_moves[0] -= 1
				if remaining_moves[0] <= 0:
					_restack_cards()
			)
		elif not c.is_moving:
			if not animate_cards.is_empty() and c.position != target_pos:
				c.animate_to(target_pos, 0.0, Vector2.ONE, duration * 0.7)
			else:
				c.position = target_pos

		y += dy_vis if c.is_face_up else dy_hid

func _on_stock_clicked(event: InputEvent) -> void:
	if is_auto_finishing or _is_any_card_moving():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_draw_from_stock()

func _draw_from_stock() -> void:
	for c in waste:
		if c.is_moving:
			c.stop_movement()
			c.position = WASTE_POS

	if stock.is_empty():
		if waste.is_empty():
			return
		# Recycle waste back into stock
		undo_stack.append({
			"type": "recycle",
			"count": waste.size(),
			"prev_score": score
		})

		if difficulty == "Standard" and not is_auto_finishing:
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
	var remaining_drawn: Array = [drawn.size()]
	var anim_dur: float = 0.08 if is_auto_finishing else 0.18
	for i in range(drawn.size()):
		var c: SolitaireCard = drawn[i]
		var tween: Tween = c.animate_to(WASTE_POS, 0.0, Vector2.ONE, anim_dur)
		tween.chain().tween_callback(func():
			remaining_drawn[0] -= 1
			if remaining_drawn[0] <= 0:
				_restack_cards()
		)

	_restack_cards()
	_update_hud()
	_check_auto_finish_available()

func _on_card_clicked(card: SolitaireCard) -> void:
	if is_auto_finishing or _is_any_card_moving():
		return

	if card.pile_type == "stock":
		_draw_from_stock()
		return

	# If face-down card in tableau is at the top of its column: flip it face up!
	if card.pile_type == "tableau" and not card.is_face_up:
		var col: Array = tableau[card.pile_index]
		if col.back() == card:
			card.flip_to(true, 0.22)
			score += 5
			moves_count += 1
			undo_stack.append({
				"type": "flip",
				"card": card,
				"prev_score": score - 5
			})
			_spawn_floating_score(card.position + Vector2(CARD_WIDTH * 0.5, 0), "+5", Color(0.85, 0.95, 0.9))
			_bounce_hud_score()
			_restack_cards()
			_update_hud()
			_check_auto_finish_available()
		return

	# Single click face-up card: attempt auto move to Foundation or best Tableau spot
	_attempt_auto_move(card)

func _on_card_double_clicked(card: SolitaireCard) -> void:
	if is_auto_finishing or not card.is_face_up or _is_any_card_moving():
		return
	_attempt_move_to_foundation(card)

func _attempt_auto_move(card: SolitaireCard) -> bool:
	if card.is_moving or _is_any_card_moving():
		return false
	# 1. Try Foundation first
	if _attempt_move_to_foundation(card):
		return true

	# 2. Try Tableau move
	if card.pile_type == "waste" or card.pile_type == "tableau":
		return _attempt_move_to_tableau(card)

	return false

func _attempt_move_to_foundation(card: SolitaireCard) -> bool:
	if card.is_moving or _is_any_card_moving():
		return false
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
		waste.erase(card)
	elif source_type == "tableau":
		tableau[source_idx].erase(card)
		if not tableau[source_idx].is_empty() and not tableau[source_idx].back().is_face_up:
			flipped_prev = tableau[source_idx].back()
			flipped_prev.flip_to(true, 0.22)
			score += 5
			_spawn_floating_score(flipped_prev.position + Vector2(CARD_WIDTH * 0.5, 0), "+5", Color(0.85, 0.95, 0.9))
			_bounce_hud_score()

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
	card.z_index = 100
	var anim_dur: float = 0.12 if is_auto_finishing else 0.2
	var tween: Tween = card.animate_to(target_pos, 0.0, Vector2.ONE, anim_dur)
	tween.chain().tween_callback(func():
		if is_auto_finishing:
			card.z_index = 20 + foundations[f_idx].size()
		else:
			_restack_cards()
		_play_foundation_score_fx(f_idx, card)
	)

	if source_type == "tableau":
		_layout_tableau_column(source_idx)

	if not is_auto_finishing:
		_restack_cards()
	_update_hud()
	_check_auto_finish_available()
	_check_victory()

func _attempt_move_to_tableau(card: SolitaireCard) -> bool:
	if card.is_moving or _is_any_card_moving():
		return false
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
			_execute_move_to_tableau(moving_cards, card.pile_type, from_col, target_col, true)
			return true

	return false

func _can_cards_go_to_tableau(bottom_card: SolitaireCard, target_col: int) -> bool:
	var col: Array = tableau[target_col]
	if col.is_empty():
		if difficulty == "Easy":
			return true # In Easy mode, any card can occupy an empty column
		return bottom_card.rank == 13 # Only King can go to empty column in Standard
	var top_card: SolitaireCard = col.back()
	return top_card.is_face_up and top_card.is_red() != bottom_card.is_red() and top_card.rank == bottom_card.rank + 1

func _execute_move_to_tableau(moving_cards: Array[SolitaireCard], from_type: String, from_col: int, to_col: int, animate: bool = true) -> void:
	var flipped_prev: SolitaireCard = null

	if from_type == "waste":
		for c in moving_cards:
			waste.erase(c)
		score += 5
		_spawn_floating_score(WASTE_POS + Vector2(CARD_WIDTH * 0.5, 0), "+5", Color(0.85, 0.95, 0.9))
		_bounce_hud_score()
	elif from_type == "tableau":
		for c in moving_cards:
			tableau[from_col].erase(c)
		if not tableau[from_col].is_empty() and not tableau[from_col].back().is_face_up:
			flipped_prev = tableau[from_col].back()
			flipped_prev.flip_to(true, 0.22)
			score += 5
			_spawn_floating_score(flipped_prev.position + Vector2(CARD_WIDTH * 0.5, 0), "+5", Color(0.85, 0.95, 0.9))
			_bounce_hud_score()
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

	_layout_tableau_column(to_col, moving_cards if animate else [], 0.2)
	if from_type == "tableau":
		_layout_tableau_column(from_col)

	_restack_cards()
	_update_hud()
	_check_auto_finish_available()

# Drag & Drop Support
func _on_card_drag_started(card: SolitaireCard, mouse_pos: Vector2) -> void:
	if is_auto_finishing or not card.is_face_up or _is_any_card_moving():
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
	var remaining_snap: Array = [count]
	for i in range(count):
		var c: SolitaireCard = _dragging_cards[i]
		var orig_pos: Vector2 = _drag_orig_positions[i]
		var tween: Tween = c.animate_to(orig_pos, 0.0, Vector2.ONE, 0.18)
		tween.chain().tween_callback(func():
			remaining_snap[0] -= 1
			if remaining_snap[0] <= 0:
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

		"wand_reveal":
			var c: SolitaireCard = rec["card"]
			c.set_face_up(false)
			score = rec["prev_score"]
			_update_hud()
			_check_auto_finish_available()
			show_toast("Wand Reveal Undone")

		"wand_move":
			var c: SolitaireCard = rec["card"]
			var from_type: String = rec["from_type"]
			var from_idx: int = rec["from_index"]
			var to_type: String = rec["to_type"]
			var to_idx: int = rec["to_index"]
			var flipped_prev: SolitaireCard = rec["flipped_prev"]

			if flipped_prev != null:
				flipped_prev.set_face_up(false)

			if to_type == "foundation":
				foundations[to_idx].erase(c)
			elif to_type == "tableau":
				tableau[to_idx].erase(c)

			if from_type == "stock":
				c.pile_type = "stock"
				c.pile_index = 0
				c.set_face_up(false)
				stock.append(c)
			elif from_type == "tableau":
				c.pile_type = "tableau"
				c.pile_index = from_idx
				c.set_face_up(false)
				tableau[from_idx].append(c)

			score = rec["prev_score"]
			_layout_all_piles_instant()
			_restack_cards()
			_update_hud()
			_check_auto_finish_available()
			show_toast("Wand Move Undone")

	_restack_cards()
	_update_hud()
	_check_auto_finish_available()

# Magic Wand Helper
func _on_wand_clicked() -> void:
	if is_auto_finishing or _is_any_card_moving():
		return

	# Strategy 1: Find any face-down card in tableau that can legally go to Foundation
	for col_idx in range(7):
		var col: Array = tableau[col_idx]
		for card_idx in range(col.size() - 1, -1, -1):
			var c: SolitaireCard = col[card_idx]
			if not c.is_face_up:
				for f_idx in range(4):
					if _can_card_go_to_foundation(c, f_idx):
						_execute_wand_card_to_foundation(c, col_idx, f_idx)
						return

	# Strategy 2: Find any face-down card in tableau that can legally go onto a face-up tableau column
	for col_idx in range(7):
		var col: Array = tableau[col_idx]
		for card_idx in range(col.size() - 1, -1, -1):
			var c: SolitaireCard = col[card_idx]
			if not c.is_face_up:
				for target_col in range(7):
					if target_col != col_idx and not tableau[target_col].is_empty():
						if _can_cards_go_to_tableau(c, target_col):
							_execute_wand_card_to_tableau(c, col_idx, target_col)
							return

	# Strategy 3: Find a playable card in Waste or Stock to Foundation
	if not waste.is_empty():
		var w_card: SolitaireCard = waste.back()
		for f_idx in range(4):
			if _can_card_go_to_foundation(w_card, f_idx):
				_execute_move_to_foundation(w_card, f_idx)
				_spawn_floating_score(FOUNDATION_POSITIONS[f_idx] + CARD_SIZE * 0.5, "+Wand!", Color(0.35, 0.9, 1.0))
				show_toast("Wand: Moved %s to Foundation" % w_card.get_display_name())
				return

	for s_idx in range(stock.size() - 1, -1, -1):
		var s_card: SolitaireCard = stock[s_idx]
		for f_idx in range(4):
			if _can_card_go_to_foundation(s_card, f_idx):
				_execute_wand_stock_to_foundation(s_card, f_idx)
				return

	# Strategy 4: Find a playable card in Waste or Stock to Tableau
	if not waste.is_empty():
		var w_card: SolitaireCard = waste.back()
		for target_col in range(7):
			if _can_cards_go_to_tableau(w_card, target_col):
				_execute_move_to_tableau([w_card], "waste", 0, target_col, true)
				_spawn_floating_score(Vector2(TABLEAU_X[target_col] + CARD_SIZE.x * 0.5, TABLEAU_Y), "+Wand!", Color(0.35, 0.9, 1.0))
				show_toast("Wand: Moved %s to Column %d" % [w_card.get_display_name(), target_col + 1])
				return

	for s_idx in range(stock.size() - 1, -1, -1):
		var s_card: SolitaireCard = stock[s_idx]
		for target_col in range(7):
			if _can_cards_go_to_tableau(s_card, target_col):
				_execute_wand_stock_to_tableau(s_card, target_col)
				return

	# Strategy 5: If there are any face-down cards left in tableau, flip the top-most hidden card face up!
	for col_idx in range(7):
		var col: Array = tableau[col_idx]
		for card_idx in range(col.size() - 1, -1, -1):
			var c: SolitaireCard = col[card_idx]
			if not c.is_face_up:
				c.flip_to(true, 0.22)
				score += 15
				moves_count += 1
				undo_stack.append({
					"type": "wand_reveal",
					"card": c,
					"prev_score": score - 15
				})
				_spawn_floating_score(c.position + Vector2(CARD_WIDTH * 0.5, 0), "+Wand!", Color(0.35, 0.9, 1.0))
				_bounce_hud_score()
				_restack_cards()
				_update_hud()
				_check_auto_finish_available()
				show_toast("Wand: Revealed %s" % c.get_display_name())
				return

	# If all tableau cards are already face-up, check if auto finish can run
	if not _is_all_on_foundations():
		_on_auto_finish_clicked()
		show_toast("Wand: Auto-Finishing Solitaire!")
		return

	show_toast("All cards are already completed!")

func _execute_wand_card_to_foundation(c: SolitaireCard, col_idx: int, f_idx: int) -> void:
	tableau[col_idx].erase(c)
	c.set_face_up(true)
	var flipped_prev: SolitaireCard = null
	if not tableau[col_idx].is_empty() and not tableau[col_idx].back().is_face_up:
		flipped_prev = tableau[col_idx].back()
		flipped_prev.flip_to(true, 0.22)
		score += 5

	c.pile_type = "foundation"
	c.pile_index = f_idx
	foundations[f_idx].append(c)

	score += 15
	moves_count += 1
	undo_stack.append({
		"type": "wand_move",
		"card": c,
		"from_type": "tableau",
		"from_index": col_idx,
		"to_type": "foundation",
		"to_index": f_idx,
		"flipped_prev": flipped_prev,
		"prev_score": score - (20 if flipped_prev else 15)
	})

	var target_pos: Vector2 = FOUNDATION_POSITIONS[f_idx]
	c.z_index = 100
	c.animate_to(target_pos, 0.0, Vector2.ONE, 0.22)
	_layout_tableau_column(col_idx)
	_spawn_floating_score(target_pos + CARD_SIZE * 0.5, "+Wand!", Color(0.35, 0.9, 1.0))
	_play_foundation_score_fx(f_idx, c)
	_restack_cards()
	_update_hud()
	_check_auto_finish_available()
	_check_victory()
	show_toast("Wand: Moved %s to Foundation" % c.get_display_name())

func _execute_wand_card_to_tableau(c: SolitaireCard, col_idx: int, target_col: int) -> void:
	tableau[col_idx].erase(c)
	c.set_face_up(true)
	var flipped_prev: SolitaireCard = null
	if not tableau[col_idx].is_empty() and not tableau[col_idx].back().is_face_up:
		flipped_prev = tableau[col_idx].back()
		flipped_prev.flip_to(true, 0.22)
		score += 5

	c.pile_type = "tableau"
	c.pile_index = target_col
	tableau[target_col].append(c)

	score += 15
	moves_count += 1
	undo_stack.append({
		"type": "wand_move",
		"card": c,
		"from_type": "tableau",
		"from_index": col_idx,
		"to_type": "tableau",
		"to_index": target_col,
		"flipped_prev": flipped_prev,
		"prev_score": score - (20 if flipped_prev else 15)
	})

	_layout_tableau_column(target_col, [c], 0.2)
	_layout_tableau_column(col_idx)
	var target_fx_pos := Vector2(TABLEAU_X[target_col] + CARD_SIZE.x * 0.5, TABLEAU_Y)
	_spawn_floating_score(target_fx_pos, "+Wand!", Color(0.35, 0.9, 1.0))
	if fx_layer != null:
		fx_layer.add_child(SolitaireFxBurst.new(target_fx_pos, false))
	_restack_cards()
	_update_hud()
	_check_auto_finish_available()
	show_toast("Wand: Moved %s to Column %d" % [c.get_display_name(), target_col + 1])

func _execute_wand_stock_to_foundation(s_card: SolitaireCard, f_idx: int) -> void:
	stock.erase(s_card)
	s_card.set_face_up(true)
	s_card.pile_type = "foundation"
	s_card.pile_index = f_idx
	foundations[f_idx].append(s_card)

	score += 15
	moves_count += 1
	undo_stack.append({
		"type": "wand_move",
		"card": s_card,
		"from_type": "stock",
		"from_index": 0,
		"to_type": "foundation",
		"to_index": f_idx,
		"flipped_prev": null,
		"prev_score": score - 15
	})

	var target_pos: Vector2 = FOUNDATION_POSITIONS[f_idx]
	s_card.z_index = 100
	s_card.animate_to(target_pos, 0.0, Vector2.ONE, 0.22)
	_spawn_floating_score(target_pos + CARD_SIZE * 0.5, "+Wand!", Color(0.35, 0.9, 1.0))
	_play_foundation_score_fx(f_idx, s_card)
	_restack_cards()
	_update_hud()
	_check_auto_finish_available()
	_check_victory()
	show_toast("Wand: Drew %s to Foundation" % s_card.get_display_name())

func _execute_wand_stock_to_tableau(s_card: SolitaireCard, target_col: int) -> void:
	stock.erase(s_card)
	s_card.set_face_up(true)
	s_card.pile_type = "tableau"
	s_card.pile_index = target_col
	tableau[target_col].append(s_card)

	score += 15
	moves_count += 1
	undo_stack.append({
		"type": "wand_move",
		"card": s_card,
		"from_type": "stock",
		"from_index": 0,
		"to_type": "tableau",
		"to_index": target_col,
		"flipped_prev": null,
		"prev_score": score - 15
	})

	_layout_tableau_column(target_col, [s_card], 0.2)
	var target_fx_pos := Vector2(TABLEAU_X[target_col] + CARD_SIZE.x * 0.5, TABLEAU_Y)
	_spawn_floating_score(target_fx_pos, "+Wand!", Color(0.35, 0.9, 1.0))
	if fx_layer != null:
		fx_layer.add_child(SolitaireFxBurst.new(target_fx_pos, false))
	_restack_cards()
	_update_hud()
	_check_auto_finish_available()
	show_toast("Wand: Drew %s to Column %d" % [s_card.get_display_name(), target_col + 1])

# Multi-Cycle Smart Hints
func _on_hint_clicked() -> void:
	if is_auto_finishing or _is_any_card_moving():
		return

	var candidate_moves: Array[Dictionary] = []

	# 1. Foundation moves from Tableau that reveal a hidden card (Highest Priority)
	for col in range(7):
		if not tableau[col].is_empty():
			var top_c: SolitaireCard = tableau[col].back()
			if top_c.is_face_up:
				for f_idx in range(4):
					if _can_card_go_to_foundation(top_c, f_idx):
						var reveals: bool = (tableau[col].size() > 1 and not tableau[col][tableau[col].size() - 2].is_face_up)
						candidate_moves.append({
							"card": top_c,
							"slot": foundation_slots[f_idx],
							"desc": "Move %s to Foundation" % top_c.get_display_name(),
							"priority": 100 if reveals else 80
						})

	# 2. Foundation moves from Waste
	if not waste.is_empty():
		var w_card: SolitaireCard = waste.back()
		for f_idx in range(4):
			if _can_card_go_to_foundation(w_card, f_idx):
				candidate_moves.append({
					"card": w_card,
					"slot": foundation_slots[f_idx],
					"desc": "Move %s to Foundation" % w_card.get_display_name(),
					"priority": 90
				})

	# 3. Tableau to Tableau moves that uncover hidden cards
	for col in range(7):
		var column: Array = tableau[col]
		if column.size() > 1:
			var first_face_up_idx: int = -1
			for i in range(column.size()):
				if column[i].is_face_up:
					first_face_up_idx = i
					break
			if first_face_up_idx > 0:
				var c: SolitaireCard = column[first_face_up_idx]
				for target_col in range(7):
					if target_col != col and _can_cards_go_to_tableau(c, target_col):
						var is_target_empty: bool = tableau[target_col].is_empty()
						candidate_moves.append({
							"card": c,
							"slot": tableau_slots[target_col],
							"desc": ("Move %s to Column %d" % [c.get_display_name(), target_col + 1]) if not is_target_empty else ("Move %s to Empty Column %d" % [c.get_display_name(), target_col + 1]),
							"priority": 85
						})

	# 4. Waste card to Tableau
	if not waste.is_empty():
		var w_card: SolitaireCard = waste.back()
		for target_col in range(7):
			if _can_cards_go_to_tableau(w_card, target_col):
				var is_target_empty: bool = tableau[target_col].is_empty()
				candidate_moves.append({
					"card": w_card,
					"slot": tableau_slots[target_col],
					"desc": ("Move %s to Column %d" % [w_card.get_display_name(), target_col + 1]) if not is_target_empty else ("Move %s to Empty Column %d" % [w_card.get_display_name(), target_col + 1]),
					"priority": 70
				})

	# 5. Moving Kings (or any card in Easy mode) to empty columns
	for col in range(7):
		var column: Array = tableau[col]
		if not column.is_empty():
			var first_face_up_idx: int = -1
			for i in range(column.size()):
				if column[i].is_face_up:
					first_face_up_idx = i
					break
			if first_face_up_idx == 0 and column.size() > 0:
				var lead: SolitaireCard = column[0]
				for target_col in range(7):
					if target_col != col and _can_cards_go_to_tableau(lead, target_col):
						if not tableau[target_col].is_empty():
							candidate_moves.append({
								"card": lead,
								"slot": tableau_slots[target_col],
								"desc": "Move %s to Column %d to free Column %d" % [lead.get_display_name(), target_col + 1, col + 1],
								"priority": 60
							})

	# 6. Any sub-stack moves that consolidate cards
	for col in range(7):
		var column: Array = tableau[col]
		for i in range(1, column.size()):
			if column[i].is_face_up:
				var c: SolitaireCard = column[i]
				for target_col in range(7):
					if target_col != col and not tableau[target_col].is_empty() and _can_cards_go_to_tableau(c, target_col):
						candidate_moves.append({
							"card": c,
							"slot": tableau_slots[target_col],
							"desc": "Move %s to Column %d" % [c.get_display_name(), target_col + 1],
							"priority": 50
						})

	# 7. Stock draw / recycle
	if not stock.is_empty():
		candidate_moves.append({
			"card": null,
			"slot": stock_slot,
			"desc": "Draw from Stock",
			"priority": 30
		})
	elif not waste.is_empty():
		candidate_moves.append({
			"card": null,
			"slot": stock_slot,
			"desc": "Recycle Waste to Stock",
			"priority": 25
		})

	if candidate_moves.is_empty():
		show_toast("No moves available. Try Undo or Wand!")
		return

	# Sort by priority descending
	candidate_moves.sort_custom(func(a, b): return a["priority"] > b["priority"])

	# Multi-hint cycling
	_last_hint_index = (_last_hint_index + 1) % candidate_moves.size()
	var chosen: Dictionary = candidate_moves[_last_hint_index]

	if chosen["card"] != null:
		_highlight_hint(chosen["card"], chosen["slot"])
	else:
		_highlight_hint_slot(chosen["slot"])

	if candidate_moves.size() > 1:
		show_toast("Hint (%d/%d): %s" % [_last_hint_index + 1, candidate_moves.size(), chosen["desc"]])
	else:
		show_toast("Hint: %s" % chosen["desc"])

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
	if is_game_over or is_auto_finishing:
		btn_auto_finish.visible = false
		return

	# If all tableau cards are face-up, auto-finish is ready!
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
	if is_auto_finishing or _is_any_card_moving():
		return
	is_auto_finishing = true
	btn_auto_finish.visible = false
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()

	var max_iterations := 300
	var iter := 0
	var consecutive_draws_without_move := 0
	while not _is_all_on_foundations() and iter < max_iterations:
		iter += 1
		var moved_any: bool = false

		# 1. Try tableau to foundation
		for col in range(7):
			if not tableau[col].is_empty():
				var c: SolitaireCard = tableau[col].back()
				for f_idx in range(4):
					if _can_card_go_to_foundation(c, f_idx):
						_execute_move_to_foundation(c, f_idx)
						moved_any = true
						consecutive_draws_without_move = 0
						await get_tree().create_timer(0.08).timeout
						break
				if moved_any:
					break

		if moved_any:
			continue

		# 2. Try waste to foundation
		if not waste.is_empty():
			var w: SolitaireCard = waste.back()
			for f_idx in range(4):
				if _can_card_go_to_foundation(w, f_idx):
					_execute_move_to_foundation(w, f_idx)
					moved_any = true
					consecutive_draws_without_move = 0
					await get_tree().create_timer(0.08).timeout
					break
			if moved_any:
				continue

		# 3. Try waste to tableau (to unblock waste)
		if not waste.is_empty():
			var w: SolitaireCard = waste.back()
			for target_col in range(7):
				if _can_cards_go_to_tableau(w, target_col):
					_execute_move_to_tableau([w], "waste", 0, target_col, true)
					moved_any = true
					consecutive_draws_without_move = 0
					await get_tree().create_timer(0.08).timeout
					break
			if moved_any:
				continue

		# 4. Draw from stock to waste or recycle waste
		var total_deck_size := stock.size() + waste.size()
		if total_deck_size > 0 and consecutive_draws_without_move <= (total_deck_size + 2):
			_draw_from_stock()
			consecutive_draws_without_move += 1
			await get_tree().create_timer(0.08).timeout
			continue

		# No further moves possible
		break

	# Allow in-flight cards to finish landing
	var wait_iter := 0
	while _is_any_card_moving() and wait_iter < 8:
		wait_iter += 1
		await get_tree().create_timer(0.05).timeout

	for c in all_cards:
		if is_instance_valid(c) and c.is_moving:
			c.stop_movement()

	is_auto_finishing = false

	# Smoothly return camera to origin
	if camera != null:
		var tw: Tween = create_tween()
		tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(camera, "offset", Vector2.ZERO, 0.2)

	_restack_cards()
	_check_victory()
	_check_auto_finish_available()

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

var _shake_tween: Tween = null

func shake_camera(intensity: float = 5.0, duration: float = 0.22) -> void:
	if camera == null:
		return
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()

	_shake_tween = create_tween()
	var steps := 8
	var step_time := duration / float(steps)
	for i in range(steps):
		var damp := 1.0 - (float(i) / float(steps))
		var offset := Vector2(
			randf_range(-intensity, intensity) * damp,
			randf_range(-intensity, intensity) * damp
		)
		_shake_tween.tween_property(camera, "offset", offset, step_time).set_trans(Tween.TRANS_SINE)
	_shake_tween.tween_property(camera, "offset", Vector2.ZERO, step_time)

func _play_foundation_score_fx(f_idx: int, card: SolitaireCard) -> void:
	if is_auto_finishing:
		# During auto-finish, camera shake is handled smoothly as a sustained rumble in _process.
		# Celebrate completed foundation suits (Kings) while maintaining 60+ FPS.
		if card.rank == 13 and fx_layer != null:
			var king_center: Vector2 = FOUNDATION_POSITIONS[f_idx] + CARD_SIZE * 0.5
			var burst := SolitaireFxBurst.new(king_center, false)
			fx_layer.add_child(burst)
		return

	# 1. Camera Shake
	if card.rank == 1:
		shake_camera(7.5, 0.25)
	else:
		shake_camera(5.0, 0.2)

	# 2. Card Landing Elastic Bounce
	var pop_tween: Tween = create_tween()
	pop_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop_tween.tween_property(card, "scale", Vector2(1.14, 1.14), 0.08)
	pop_tween.tween_property(card, "scale", Vector2.ONE, 0.12)

	# 3. Foundation Slot Glow Pulse
	if f_idx >= 0 and f_idx < foundation_slots.size():
		var slot: Panel = foundation_slots[f_idx]
		var glow: Panel = slot.get_node_or_null("HighlightGlow")
		if glow != null:
			glow.visible = true
			glow.modulate.a = 1.0
			var glow_tween: Tween = create_tween()
			glow_tween.tween_property(glow, "modulate:a", 0.0, 0.4)
			glow_tween.tween_callback(func():
				glow.visible = false
				glow.modulate.a = 1.0
			)

	# 4. Floating Score Popup
	var slot_center: Vector2 = FOUNDATION_POSITIONS[f_idx] + CARD_SIZE * 0.5
	var score_str: String = "+10 ACE!" if card.rank == 1 else "+10"
	_spawn_floating_score(Vector2(slot_center.x, FOUNDATION_POSITIONS[f_idx].y - 8.0), score_str, Color(1.0, 0.9, 0.28))

	# 5. Golden Shockwave and Sparkle Burst
	if fx_layer != null:
		var burst := SolitaireFxBurst.new(slot_center, card.rank == 1)
		fx_layer.add_child(burst)

	# 6. HUD Score Pill Bounce
	_bounce_hud_score()

func _spawn_floating_score(pos: Vector2, text: String, color: Color = Color(1.0, 0.9, 0.25)) -> void:
	if fx_layer == null:
		return

	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.08, 0.05, 0.95))
	label.add_theme_constant_override("outline_size", 5)
	label.add_theme_font_size_override("font_size", 22)

	label.size = Vector2(160, 36)
	label.position = pos - Vector2(80, 18)
	label.pivot_offset = Vector2(80, 18)
	label.scale = Vector2(0.5, 0.5)

	fx_layer.add_child(label)

	var tween: Tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2(1.22, 1.22), 0.14)
	tween.chain().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(label, "scale", Vector2(0.92, 0.92), 0.38)

	var move_tween: Tween = create_tween()
	move_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	move_tween.tween_property(label, "position:y", pos.y - 45.0, 0.52)

	var fade_tween: Tween = create_tween()
	fade_tween.tween_interval(0.26)
	fade_tween.tween_property(label, "modulate:a", 0.0, 0.26)
	fade_tween.tween_callback(label.queue_free)

func _bounce_hud_score() -> void:
	if score_pill == null:
		return
	score_pill.pivot_offset = score_pill.size * 0.5
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(score_pill, "scale", Vector2(1.15, 1.15), 0.08)
	tween.tween_property(score_pill, "scale", Vector2.ONE, 0.13)
