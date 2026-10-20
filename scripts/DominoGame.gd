class_name DominoGame
extends Node2D

## Main Domino Game Orchestrator.
## Controls game loop, turns, dealing, shuffling, AI turns, and UI.

enum State {
	SETUP,
	SHUFFLE,
	DEAL,
	DETERMINE_FIRST,
	PLAYING,
	ROUND_OVER
}

var current_state: State = State.SETUP
var num_opponents: int = 1
var players: Array[Player] = []
var current_player_idx: int = 0
var consecutive_passes: int = 0

var boneyard: Array[DominoTile] = []
var all_tiles: Array[DominoTile] = []

# Preloaded scenes and classes
const TileScene = preload("res://scenes/domino_tile.tscn")
const DominoPlacementSlotClass = preload("res://scripts/DominoPlacementSlot.gd")

var selected_hand_tile: DominoTile = null
var _active_placement_slots: Array[Node2D] = []
var is_animating: bool = false

# Node references
@onready var board: DominoBoard = $BoardContainer/DominoBoard
@onready var board_container: Node2D = $BoardContainer
@onready var tile_layer: Control = $UICanvas/TileLayer

# UI references
@onready var ui_canvas: CanvasLayer = $UICanvas
@onready var opponent_dialog: OpponentDialog = $UICanvas/OpponentDialog
@onready var turn_label: Label = $UICanvas/HUD/TopBar/HBox/TurnPill/TurnLabel
@onready var boneyard_panel: PanelContainer = $UICanvas/HUD/BoneyardPanel
@onready var boneyard_btn: Button = $UICanvas/HUD/BoneyardPanel/VBox/BoneyardBtn
@onready var boneyard_count_label: Label = $UICanvas/HUD/BoneyardPanel/VBox/CountLabel
@onready var pass_btn: Button = $UICanvas/HUD/PassBtn
@onready var new_game_btn: Button = $UICanvas/HUD/TopBar/HBox/NewGameBtn
@onready var menu_btn: Button = $UICanvas/HUD/TopBar/HBox/MenuBtn
@onready var center_view_btn: Button = $UICanvas/HUD/TopBar/HBox/CenterViewBtn

# Hand Containers / Areas
@onready var human_hand_container: Control = $UICanvas/HumanHandArea/HandSlots
@onready var opponent_top_container: Control = $UICanvas/OpponentTopArea
@onready var opponent_left_container: Control = $UICanvas/OpponentLeftArea
@onready var opponent_right_container: Control = $UICanvas/OpponentRightArea

# Badges
@onready var human_badge: PanelContainer = $UICanvas/HumanHandArea/Badge
@onready var human_badge_pips: Label = $UICanvas/HumanHandArea/Badge/HBox/PipsLabel

@onready var top_badge: PanelContainer = $UICanvas/OpponentTopArea/Badge
@onready var top_badge_name: Label = $UICanvas/OpponentTopArea/Badge/HBox/NameLabel
@onready var top_badge_count: Label = $UICanvas/OpponentTopArea/Badge/HBox/CountLabel

@onready var left_badge: PanelContainer = $UICanvas/OpponentLeftArea/Badge
@onready var left_badge_name: Label = $UICanvas/OpponentLeftArea/Badge/HBox/NameLabel
@onready var left_badge_count: Label = $UICanvas/OpponentLeftArea/Badge/HBox/CountLabel

@onready var right_badge: PanelContainer = $UICanvas/OpponentRightArea/Badge
@onready var right_badge_name: Label = $UICanvas/OpponentRightArea/Badge/HBox/NameLabel
@onready var right_badge_count: Label = $UICanvas/OpponentRightArea/Badge/HBox/CountLabel

# End selection markers on board
@onready var btn_play_left: Button = $UICanvas/PlacementPrompt/HBox/BtnPlayLeft
@onready var btn_play_right: Button = $UICanvas/PlacementPrompt/HBox/BtnPlayRight
@onready var btn_cancel_prompt: Button = $UICanvas/PlacementPrompt/HBox/BtnCancel
@onready var placement_prompt: Control = $UICanvas/PlacementPrompt

# Game Over Dialog
@onready var game_over_panel: Control = $UICanvas/GameOverDialog
@onready var game_over_box: PanelContainer = $UICanvas/GameOverDialog/Panel
@onready var winner_title: Label = $UICanvas/GameOverDialog/Panel/VBox/Title
@onready var score_details: Label = $UICanvas/GameOverDialog/Panel/VBox/Details
@onready var btn_play_again: Button = $UICanvas/GameOverDialog/Panel/VBox/ButtonsHBox/BtnPlayAgain
@onready var btn_change_settings: Button = $UICanvas/GameOverDialog/Panel/VBox/ButtonsHBox/BtnChangeSettings
@onready var btn_main_menu: Button = $UICanvas/GameOverDialog/Panel/VBox/ButtonsHBox/BtnMainMenu

# Toast announcement
@onready var toast_panel: PanelContainer = $UICanvas/ToastPanel
@onready var toast_label: Label = $UICanvas/ToastPanel/ToastLabel

# Badge styles
var _badge_normal_style: StyleBoxFlat
var _badge_active_style: StyleBoxFlat

# Boneyard spawn position (bottom-left, above Boneyard panel)
var boneyard_pos: Vector2 = Vector2(84, 480)

# Board drag and zoom state
var _is_panning: bool = false
var _pan_start_mouse: Vector2 = Vector2.ZERO
var _pan_start_board: Vector2 = Vector2.ZERO

func _ready() -> void:
	_init_badge_styles()
	_setup_ui_signals()
	var vp_size: Vector2 = get_viewport_rect().size
	boneyard_pos = Vector2(84.0, vp_size.y - 195.0)
	board_container.position = vp_size * 0.5

	num_opponents = GameSettings.classic_opponents
	start_new_match()

func _init_badge_styles() -> void:
	_badge_normal_style = StyleBoxFlat.new()
	_badge_normal_style.bg_color = Color(0.06, 0.08, 0.10, 0.88)
	_badge_normal_style.border_width_left = 1
	_badge_normal_style.border_width_top = 1
	_badge_normal_style.border_width_right = 1
	_badge_normal_style.border_width_bottom = 1
	_badge_normal_style.border_color = Color(1.0, 1.0, 1.0, 0.1)
	_badge_normal_style.corner_radius_top_left = 12
	_badge_normal_style.corner_radius_top_right = 12
	_badge_normal_style.corner_radius_bottom_right = 12
	_badge_normal_style.corner_radius_bottom_left = 12
	_badge_normal_style.shadow_color = Color(0, 0, 0, 0.3)
	_badge_normal_style.shadow_size = 5
	_badge_normal_style.content_margin_left = 14.0
	_badge_normal_style.content_margin_top = 5.0
	_badge_normal_style.content_margin_right = 14.0
	_badge_normal_style.content_margin_bottom = 5.0

	_badge_active_style = StyleBoxFlat.new()
	_badge_active_style.bg_color = Color(0.09, 0.13, 0.16, 0.96)
	_badge_active_style.border_width_left = 1
	_badge_active_style.border_width_top = 1
	_badge_active_style.border_width_right = 1
	_badge_active_style.border_width_bottom = 1
	_badge_active_style.border_color = Color(0.92, 0.8, 0.38, 0.95)
	_badge_active_style.corner_radius_top_left = 12
	_badge_active_style.corner_radius_top_right = 12
	_badge_active_style.corner_radius_bottom_right = 12
	_badge_active_style.corner_radius_bottom_left = 12
	_badge_active_style.shadow_color = Color(0.92, 0.8, 0.38, 0.25)
	_badge_active_style.shadow_size = 8
	_badge_active_style.content_margin_left = 14.0
	_badge_active_style.content_margin_top = 5.0
	_badge_active_style.content_margin_right = 14.0
	_badge_active_style.content_margin_bottom = 5.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Check if user clicked on any active placement slot on the board
			for slot in _active_placement_slots:
				if is_instance_valid(slot) and slot.is_event_inside(event):
					slot.handle_click()
					get_viewport().set_input_as_handled()
					return

			# If user clicked empty table/board while placement slots are open, cancel selection
			if selected_hand_tile != null and _active_placement_slots.size() > 0:
				_on_cancel_prompt_clicked()
				return
		elif event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				_is_panning = true
				_pan_start_mouse = event.position
				_pan_start_board = board_container.position
			else:
				_is_panning = false
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			var new_scale: float = clampf(board_container.scale.x * 1.08, 0.35, 1.8)
			board_container.scale = Vector2.ONE * new_scale
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			var new_scale: float = clampf(board_container.scale.x * 0.92, 0.35, 1.8)
			board_container.scale = Vector2.ONE * new_scale
	elif event is InputEventMouseMotion and _is_panning:
		board_container.position = _pan_start_board + (event.position - _pan_start_mouse)

func _setup_ui_signals() -> void:
	opponent_dialog.setup_confirmed.connect(_on_setup_confirmed)
	boneyard_btn.pressed.connect(_on_boneyard_clicked)
	boneyard_panel.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_on_boneyard_clicked()
	)
	pass_btn.pressed.connect(_on_pass_clicked)
	new_game_btn.pressed.connect(show_setup_dialog)
	menu_btn.pressed.connect(_on_menu_clicked)
	center_view_btn.pressed.connect(reset_board_view)

	btn_play_left.pressed.connect(func(): _commit_player_move("left"))
	btn_play_right.pressed.connect(func(): _commit_player_move("right"))
	btn_cancel_prompt.pressed.connect(_on_cancel_prompt_clicked)

	btn_play_again.pressed.connect(_on_play_again_pressed)
	btn_change_settings.pressed.connect(show_setup_dialog)
	btn_main_menu.pressed.connect(_on_menu_clicked)

	pass_btn.visible = false
	placement_prompt.visible = false
	game_over_panel.visible = false
	toast_panel.visible = false

func _on_cancel_prompt_clicked() -> void:
	if selected_hand_tile != null:
		selected_hand_tile.set_selected(false)
	_clear_placement_slots()
	placement_prompt.visible = false
	selected_hand_tile = null
	turn_label.text = "Your Turn"

func show_setup_dialog() -> void:
	current_state = State.SETUP
	opponent_dialog.open_modal()
	game_over_panel.hide()
	placement_prompt.hide()

func _on_menu_clicked() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_setup_confirmed(opponents: int, theme_name: String) -> void:
	num_opponents = opponents
	GameSettings.classic_opponents = opponents
	ThemeManager.set_theme(theme_name)
	start_new_match()

func _on_play_again_pressed() -> void:
	game_over_panel.hide()
	start_new_match()

func start_new_match() -> void:
	opponent_dialog.hide()
	game_over_panel.hide()
	placement_prompt.hide()
	_clear_placement_slots()

	# Clear previous match tiles and board
	_clear_all_tiles()
	board.reset()
	reset_board_view()

	# Create Players
	players.clear()
	# Player 0: Human
	players.append(Player.new(0, "You", true))

	# AI Players
	var ai_names: Array[String] = ["Alex", "Bob", "Chloe"]
	for i in range(num_opponents):
		var p_name: String = ai_names[i % ai_names.size()]
		players.append(AIPlayer.new(i + 1, p_name))

	_update_opponent_panels()
	_update_all_player_badges()
	consecutive_passes = 0

	# Generate full Double-Six 28 tile set
	_generate_tiles()

	# Start Shuffle Phase
	start_shuffle_phase()

func _clear_all_tiles() -> void:
	for t in all_tiles:
		if is_instance_valid(t):
			t.queue_free()
	all_tiles.clear()
	boneyard.clear()
	selected_hand_tile = null

func _get_boneyard_slot_position(index: int) -> Vector2:
	var stack_depth: float = -0.6 * minf(float(index), 16.0)
	var center: Vector2 = boneyard_pos + Vector2(0.0, stack_depth)
	return center - Vector2(28.0, 56.0)

func _update_boneyard_stack(duration: float = 0.25) -> void:
	for i in range(boneyard.size()):
		var tile: DominoTile = boneyard[i]
		var target_pos: Vector2 = _get_boneyard_slot_position(i)
		tile.boneyard_base_pos = target_pos
		tile.owner_id = -1
		tile.is_interactable = true
		tile.rotation = 0.0
		if duration <= 0.0:
			tile.position = target_pos
			tile.scale = Vector2(0.65, 0.65)
			tile.z_index = i
		else:
			tile.animate_to(target_pos, 0.0, Vector2(0.65, 0.65), duration, false, 24.0, i)
	_update_boneyard_interactivity(current_player_idx == 0 and current_state == State.PLAYING and players.size() > 0 and not players[0].has_playable(board))

func _generate_tiles() -> void:
	all_tiles.clear()
	boneyard.clear()

	for a in range(7):
		for b in range(a, 7):
			var tile: DominoTile = TileScene.instantiate()
			tile_layer.add_child(tile)
			tile.setup(a, b, false, -1)
			tile.scale = Vector2(0.65, 0.65)
			tile.tile_clicked.connect(_on_tile_clicked)
			all_tiles.append(tile)
			boneyard.append(tile)

	_update_boneyard_count()
	_update_boneyard_stack(0.0)

## Shuffle animation: swirling, spreading and gathering
func start_shuffle_phase() -> void:
	current_state = State.SHUFFLE
	is_animating = true
	turn_label.text = "Shuffling"
	SoundManager.play_shuffle()

	boneyard.shuffle()

	var vp_size: Vector2 = get_viewport_rect().size
	var table_center: Vector2 = vp_size * 0.5
	var max_delay: float = 0.15
	var shuffle_dur: float = 0.65

	for i in range(boneyard.size()):
		var tile: DominoTile = boneyard[i]
		tile.z_index = 10 + i
		var delay: float = randf_range(0.0, max_delay)
		tile.animate_shuffle(table_center, delay, shuffle_dur)

	await get_tree().create_timer(max_delay + shuffle_dur + 0.1).timeout

	_update_boneyard_stack(0.4)
	await get_tree().create_timer(0.45).timeout
	start_deal_phase()

## Dealing animation: dealing tiles to human and AI hands
func start_deal_phase() -> void:
	current_state = State.DEAL
	turn_label.text = "Dealing"

	var tiles_per_player: int = 7
	if players.size() == 4:
		tiles_per_player = 6

	for round_num in range(tiles_per_player):
		for p_idx in range(players.size()):
			if boneyard.is_empty():
				break
			var player: Player = players[p_idx]
			var tile: DominoTile = boneyard.pop_back()
			player.add_tile(tile)
			_update_boneyard_count()
			_update_all_player_badges()

			var target_pos: Vector2 = _get_player_hand_slot_position(p_idx, round_num, tiles_per_player)
			tile.hand_base_pos = target_pos
			var target_scale: Vector2 = Vector2.ONE if p_idx == 0 else Vector2(0.65, 0.65)
			SoundManager.play_deal()
			tile.animate_to(target_pos, 0.0, target_scale, 0.22, false, 24.0, round_num)
			await get_tree().create_timer(0.06).timeout

	_update_boneyard_stack(0.2)
	await get_tree().create_timer(0.25).timeout

	_arrange_all_hands()

	await get_tree().create_timer(0.15).timeout
	var human_hand: Array[DominoTile] = players[0].hand
	for i in range(human_hand.size()):
		var tile: DominoTile = human_hand[i]
		tile.flip_to(true, 0.28)
		await get_tree().create_timer(0.06).timeout

	await get_tree().create_timer(0.3).timeout
	_determine_first_turn()

## Determine which player has the highest double or highest tile
func _determine_first_turn() -> void:
	current_state = State.DETERMINE_FIRST

	var starter_idx: int = 0
	var highest_dbl: DominoTile = null

	for i in range(players.size()):
		var p_dbl: DominoTile = players[i].get_highest_double()
		if p_dbl != null:
			if highest_dbl == null or p_dbl.top_val > highest_dbl.top_val:
				highest_dbl = p_dbl
				starter_idx = i

	if highest_dbl == null:
		var highest_tile: DominoTile = null
		for i in range(players.size()):
			var p_tile: DominoTile = players[i].get_highest_tile()
			if p_tile != null:
				if highest_tile == null or p_tile.pip_sum() > highest_tile.pip_sum():
					highest_tile = p_tile
					starter_idx = i

	current_player_idx = starter_idx
	var starter: Player = players[current_player_idx]

	if starter.is_human:
		show_toast("You go first")
	else:
		show_toast("%s goes first" % starter.name)

	await get_tree().create_timer(1.0).timeout
	_arrange_all_hands()
	_update_all_player_badges()
	start_playing_turn()

func start_playing_turn() -> void:
	current_state = State.PLAYING
	is_animating = false
	placement_prompt.hide()
	_clear_placement_slots()
	selected_hand_tile = null

	var current_player: Player = players[current_player_idx]
	_highlight_active_player(current_player_idx)

	if current_player.is_human:
		_start_human_turn()
	else:
		_start_ai_turn()

func _start_human_turn() -> void:
	var human: Player = players[0]
	var playable: Array[DominoTile] = human.get_playable_tiles(board)

	for tile in human.hand:
		tile.set_playable(playable.has(tile))

	var can_draw: bool = playable.is_empty() and boneyard.size() > 0
	_update_boneyard_interactivity(can_draw)

	if playable.size() > 0:
		turn_label.text = "Your Turn"
		pass_btn.visible = false
		boneyard_btn.disabled = true
	else:
		if boneyard.size() > 0:
			turn_label.text = "Draw a Tile"
			pass_btn.visible = false
			boneyard_btn.disabled = false
		else:
			turn_label.text = "Pass"
			pass_btn.visible = true
			boneyard_btn.disabled = true

func _update_boneyard_interactivity(can_draw: bool) -> void:
	if boneyard.is_empty():
		return
	var top_tile: DominoTile = boneyard.back()
	for i in range(boneyard.size()):
		var t: DominoTile = boneyard[i]
		t.is_interactable = true
		if t == top_tile and can_draw:
			t.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			t.set_playable(true)
		else:
			t.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if (current_player_idx == 0 and current_state == State.PLAYING) else Control.CURSOR_ARROW
			t.set_playable(false)

func _on_tile_clicked(tile: DominoTile) -> void:
	if current_state != State.PLAYING or is_animating:
		return
	if current_player_idx != 0:
		return

	if tile.owner_id == -1 or boneyard.has(tile):
		_on_boneyard_clicked()
		return

	if tile.owner_id != 0 or not tile.is_playable:
		return

	# If the user clicks the currently selected tile again, deselect it!
	if selected_hand_tile == tile:
		_clear_placement_slots()
		tile.set_selected(false)
		selected_hand_tile = null
		turn_label.text = "Your Turn"
		return

	if selected_hand_tile != null:
		selected_hand_tile.set_selected(false)
	_clear_placement_slots()

	SoundManager.play_click()
	selected_hand_tile = tile

	if board.is_empty():
		_commit_player_move("first")
		return

	var valid_ends: Array[String] = board.get_valid_ends(tile)
	if valid_ends.size() == 1:
		_commit_player_move(valid_ends[0])
	elif valid_ends.size() > 1:
		tile.set_selected(true)
		_show_placement_slots(tile, valid_ends)

func _show_placement_slots(tile: DominoTile, valid_ends: Array[String]) -> void:
	_clear_placement_slots()
	turn_label.text = "Choose End"
	placement_prompt.visible = false

	btn_play_left.text = "Left | %d" % board.open_left_val
	btn_play_right.text = "Right | %d" % board.open_right_val

	for end_choice in valid_ends:
		var preview: Dictionary = board.get_placement_preview(tile, end_choice)
		var slot: Node2D = DominoPlacementSlotClass.new()
		slot.choice = end_choice
		slot.slot_label = end_choice.capitalize()
		slot.open_val = board.get_open_val(end_choice)
		slot.position = preview["position"]
		slot.rotation = preview["rotation"]
		slot.slot_clicked.connect(func(chosen_end: String):
			_commit_player_move(chosen_end)
		)
		board.add_child(slot)
		_active_placement_slots.append(slot)

func _clear_placement_slots() -> void:
	for slot in _active_placement_slots:
		if is_instance_valid(slot):
			slot.queue_free()
	_active_placement_slots.clear()

func _commit_player_move(end_choice: String) -> void:
	if selected_hand_tile == null:
		return
	_clear_placement_slots()
	placement_prompt.visible = false
	consecutive_passes = 0
	var tile: DominoTile = selected_hand_tile
	tile.set_selected(false)
	selected_hand_tile = null

	players[0].remove_tile(tile)
	tile.owner_id = -1
	tile.set_playable(false)

	for t in players[0].hand:
		t.set_playable(false)

	_execute_tile_placement(tile, end_choice)

func _execute_tile_placement(tile: DominoTile, end_choice: String) -> void:
	is_animating = true
	var place_info: Dictionary = board.place_tile(tile, end_choice)

	tile.set_face_up(true)

	var target_pos: Vector2 = board.to_global(place_info["position"]) - tile.size * 0.5
	var target_rot: float = place_info["rotation"]

	tile.animate_to(target_pos, target_rot, Vector2.ONE, 0.38, true)

	await get_tree().create_timer(0.4).timeout

	tile.reparent(board, false)
	tile.position = place_info["position"] - tile.size * 0.5
	tile.rotation = target_rot
	tile.scale = Vector2.ONE
	tile.is_interactable = false
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_arrange_all_hands()
	_update_all_player_badges()
	_update_board_framing()
	_check_round_end_or_next_turn()

func _start_ai_turn() -> void:
	for tile in players[0].hand:
		tile.set_playable(false)
	_update_boneyard_interactivity(false)
	boneyard_btn.disabled = true
	pass_btn.visible = false

	var ai: AIPlayer = players[current_player_idx] as AIPlayer
	turn_label.text = "%s" % ai.name

	await get_tree().create_timer(0.85).timeout

	var move: Dictionary = ai.choose_move(board)

	if not move.is_empty():
		consecutive_passes = 0
		var tile: DominoTile = move["tile"]
		var end_choice: String = move["end"]
		ai.remove_tile(tile)
		tile.owner_id = -1

		tile.flip_to(true, 0.28)
		_execute_tile_placement(tile, end_choice)
	else:
		if boneyard.size() > 0:
			_ai_draw_tile(ai)
		else:
			SoundManager.play_pass()
			show_toast("%s passed" % ai.name)
			consecutive_passes += 1
			await get_tree().create_timer(0.8).timeout
			_check_round_end_or_next_turn()

func _ai_draw_tile(ai: AIPlayer) -> void:
	var tile: DominoTile = boneyard.pop_back()
	ai.add_tile(tile)
	_update_boneyard_count()
	_update_boneyard_stack(0.2)
	_update_all_player_badges()

	show_toast("%s drew" % ai.name)
	SoundManager.play_draw()

	var target_pos: Vector2 = _get_player_hand_slot_position(current_player_idx, ai.hand_size() - 1, ai.hand_size())
	tile.animate_to(target_pos, 0.0, Vector2(0.65, 0.65), 0.25, false, 24.0, ai.hand_size() - 1)

	await get_tree().create_timer(0.3).timeout
	_arrange_all_hands()

	var move: Dictionary = ai.choose_move(board)
	if not move.is_empty():
		await get_tree().create_timer(0.5).timeout
		consecutive_passes = 0
		var play_tile: DominoTile = move["tile"]
		var end_choice: String = move["end"]
		ai.remove_tile(play_tile)
		play_tile.owner_id = -1
		play_tile.flip_to(true, 0.28)
		_execute_tile_placement(play_tile, end_choice)
	else:
		if boneyard.size() > 0:
			await get_tree().create_timer(0.4).timeout
			_ai_draw_tile(ai)
		else:
			SoundManager.play_pass()
			show_toast("%s passed" % ai.name)
			consecutive_passes += 1
			await get_tree().create_timer(0.8).timeout
			_check_round_end_or_next_turn()

func _on_boneyard_clicked() -> void:
	if current_state != State.PLAYING or is_animating:
		return
	if current_player_idx != 0:
		return
	if boneyard.is_empty():
		return

	var human: Player = players[0]
	if human.has_playable(board):
		SoundManager.play_invalid()
		show_toast("Play from hand")
		return

	is_animating = true
	_update_boneyard_interactivity(false)

	var tile: DominoTile = boneyard.pop_back()
	human.add_tile(tile)
	_update_boneyard_count()
	_update_boneyard_stack(0.2)
	_update_all_player_badges()

	_arrange_all_hands()

	SoundManager.play_draw()
	var target_pos: Vector2 = _get_player_hand_slot_position(0, human.hand_size() - 1, human.hand_size())
	tile.hand_base_pos = target_pos
	tile.animate_to(target_pos, 0.0, Vector2.ONE, 0.28, false, 24.0, 5)

	await get_tree().create_timer(0.3).timeout
	tile.flip_to(true, 0.3)
	await get_tree().create_timer(0.25).timeout

	_arrange_all_hands()
	is_animating = false
	_start_human_turn()

func _on_pass_clicked() -> void:
	if current_state != State.PLAYING or is_animating or current_player_idx != 0:
		return
	is_animating = true
	pass_btn.visible = false
	SoundManager.play_pass()
	show_toast("Passed")
	consecutive_passes += 1
	await get_tree().create_timer(0.6).timeout
	is_animating = false
	_check_round_end_or_next_turn()

func _check_round_end_or_next_turn() -> void:
	var current_player: Player = players[current_player_idx]
	if current_player.hand_size() == 0:
		_end_round_winner(current_player, false)
		return

	if consecutive_passes >= players.size() and boneyard.is_empty():
		_end_round_blocked()
		return

	current_player_idx = (current_player_idx + 1) % players.size()
	start_playing_turn()

func _end_round_winner(winner: Player, _is_blocked: bool) -> void:
	current_state = State.ROUND_OVER

	for p in players:
		for t in p.hand:
			t.set_playable(false)
			t.is_interactable = false
			t.flip_to(true, 0.25)

	var points_won: int = 0
	for p in players:
		if p != winner:
			points_won += p.get_pip_sum()

	winner.round_score += points_won

	if winner.is_human:
		SoundManager.play_win()
		winner_title.text = "Victory"
		winner_title.modulate = Color(0.92, 0.8, 0.38, 1.0)
	else:
		SoundManager.play_chips()
		winner_title.text = "%s Wins" % winner.name
		winner_title.modulate = Color(0.92, 0.8, 0.38, 1.0)

	var details_lines: Array[String] = []
	for p in players:
		var pips: int = p.get_pip_sum()
		if p == winner:
			details_lines.append("%s  |  Winner  (+%d pts)" % [p.name, points_won])
		else:
			details_lines.append("%s  |  %d pips" % [p.name, pips])

	score_details.text = "\n".join(details_lines)
	_show_game_over()

func _end_round_blocked() -> void:
	current_state = State.ROUND_OVER

	for p in players:
		for t in p.hand:
			t.set_playable(false)
			t.is_interactable = false
			t.flip_to(true, 0.25)

	var min_pips: int = 99999
	var winner: Player = players[0]

	for p in players:
		var pips: int = p.get_pip_sum()
		if pips < min_pips:
			min_pips = pips
			winner = p

	var points_won: int = 0
	for p in players:
		if p != winner:
			points_won += p.get_pip_sum()

	winner.round_score += points_won

	if winner.is_human:
		SoundManager.play_win()
		winner_title.text = "Victory (Blocked)"
		winner_title.modulate = Color(0.92, 0.8, 0.38, 1.0)
	else:
		SoundManager.play_chips()
		winner_title.text = "%s Wins (Blocked)" % winner.name
		winner_title.modulate = Color(0.92, 0.8, 0.38, 1.0)

	var details_lines: Array[String] = []
	for p in players:
		var pips: int = p.get_pip_sum()
		if p == winner:
			details_lines.append("%s  |  Winner  (+%d pts)" % [p.name, points_won])
		else:
			details_lines.append("%s  |  %d pips" % [p.name, pips])

	score_details.text = "\n".join(details_lines)
	_show_game_over()

func _show_game_over() -> void:
	game_over_panel.visible = true
	game_over_panel.modulate.a = 0.0
	game_over_box.scale = Vector2(0.95, 0.95)
	var tween: Tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(game_over_panel, "modulate:a", 1.0, 0.18)
	tween.tween_property(game_over_box, "scale", Vector2.ONE, 0.18)

## Updates boneyard counter UI
func _update_boneyard_count() -> void:
	boneyard_count_label.text = "%d left" % boneyard.size()
	boneyard_btn.disabled = boneyard.is_empty()

## Arranges tiles in all players' hands nicely
func _arrange_all_hands() -> void:
	for p_idx in range(players.size()):
		var p: Player = players[p_idx]
		var count: int = p.hand_size()
		for i in range(count):
			var tile: DominoTile = p.hand[i]
			var target_pos: Vector2 = _get_player_hand_slot_position(p_idx, i, count)
			tile.hand_base_pos = target_pos
			var target_scale: Vector2 = Vector2.ONE if p_idx == 0 else Vector2(0.65, 0.65)
			tile.animate_to(target_pos, 0.0, target_scale, 0.2, false)

## Computes screen position for hand slots with adaptive overlap
func _get_player_hand_slot_position(player_idx: int, tile_index: int, total_tiles: int) -> Vector2:
	var vp_size: Vector2 = get_viewport_rect().size

	if player_idx == 0:
		var tile_w: float = 56.0
		var max_tray_width: float = vp_size.x - 340.0
		var spacing: float = 6.0
		if total_tiles > 1:
			spacing = clampf((max_tray_width - total_tiles * tile_w) / float(total_tiles - 1), -18.0, 6.0)

		var total_width: float = total_tiles * tile_w + (total_tiles - 1) * spacing
		var start_x: float = (vp_size.x - total_width) * 0.5
		var y: float = vp_size.y - 128.0
		return Vector2(start_x + tile_index * (tile_w + spacing), y)

	if num_opponents == 1:
		var tile_w: float = 38.0
		var spacing: float = 4.0
		if total_tiles > 1:
			spacing = clampf((480.0 - total_tiles * tile_w) / float(total_tiles - 1), -14.0, 4.0)
		var total_w: float = total_tiles * tile_w + (total_tiles - 1) * spacing
		var start_x: float = (vp_size.x - total_w) * 0.5
		return Vector2(start_x + tile_index * (tile_w + spacing), 60.0)

	elif num_opponents == 2:
		var tile_w: float = 34.0
		var spacing: float = 2.0
		if player_idx == 1:
			var start_x: float = 180.0
			return Vector2(start_x + tile_index * (tile_w + spacing), 60.0)
		else:
			var start_x: float = vp_size.x - 380.0
			return Vector2(start_x + tile_index * (tile_w + spacing), 60.0)

	else:
		if player_idx == 1:
			return Vector2(36.0, 160.0 + tile_index * 36.0)
		elif player_idx == 2:
			var tile_w: float = 34.0
			var total_w: float = total_tiles * tile_w
			var start_x: float = (vp_size.x - total_w) * 0.5
			return Vector2(start_x + tile_index * 34.0, 60.0)
		else:
			return Vector2(vp_size.x - 80.0, 160.0 + tile_index * 36.0)

	return Vector2.ZERO

func _update_opponent_panels() -> void:
	opponent_top_container.visible = true
	opponent_left_container.visible = (num_opponents >= 3)
	opponent_right_container.visible = (num_opponents >= 2)

func _update_all_player_badges() -> void:
	if players.is_empty():
		return

	human_badge_pips.text = "%d pips" % players[0].get_pip_sum()

	if players.size() > 1:
		top_badge_name.text = players[1].name
		top_badge_count.text = "%d tiles" % players[1].hand_size()

	if num_opponents == 2 and players.size() > 2:
		right_badge_name.text = players[2].name
		right_badge_count.text = "%d tiles" % players[2].hand_size()
	elif num_opponents == 3 and players.size() > 3:
		left_badge_name.text = players[2].name
		left_badge_count.text = "%d tiles" % players[2].hand_size()
		right_badge_name.text = players[3].name
		right_badge_count.text = "%d tiles" % players[3].hand_size()

func _set_badge_active(badge: PanelContainer, is_active: bool) -> void:
	if badge == null or _badge_active_style == null or _badge_normal_style == null:
		return
	badge.add_theme_stylebox_override("panel", _badge_active_style if is_active else _badge_normal_style)

func _highlight_active_player(p_idx: int) -> void:
	_set_badge_active(human_badge, p_idx == 0)
	_set_badge_active(top_badge, p_idx == 1)
	if num_opponents == 2:
		_set_badge_active(right_badge, p_idx == 2)
	elif num_opponents == 3:
		_set_badge_active(left_badge, p_idx == 2)
		_set_badge_active(right_badge, p_idx == 3)

## Auto-framing: adjusts board position and zoom so entire train remains centered and visible
func _update_board_framing() -> void:
	var bounds: Rect2 = board.get_board_bounds()
	if bounds.size == Vector2.ZERO:
		return

	var vp_size: Vector2 = get_viewport_rect().size
	var target_scale: float = 1.0

	var max_span_x: float = maxf(bounds.size.x, 200.0)
	var max_span_y: float = maxf(bounds.size.y, 200.0)

	var margin_x: float = vp_size.x * 0.72
	var margin_y: float = vp_size.y * 0.5

	if max_span_x > margin_x or max_span_y > margin_y:
		var scale_x: float = margin_x / max_span_x
		var scale_y: float = margin_y / max_span_y
		target_scale = clampf(minf(scale_x, scale_y), 0.45, 1.0)

	var target_center: Vector2 = vp_size * 0.5 - bounds.get_center() * target_scale

	var tween: Tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(board_container, "scale", Vector2.ONE * target_scale, 0.4)
	tween.tween_property(board_container, "position", target_center, 0.4)

func reset_board_view() -> void:
	var vp_size: Vector2 = get_viewport_rect().size
	board_container.position = vp_size * 0.5
	board_container.scale = Vector2.ONE

func show_toast(msg: String) -> void:
	toast_label.text = msg
	toast_panel.visible = true
	toast_panel.modulate.a = 0.0

	var tween: Tween = create_tween()
	tween.tween_property(toast_panel, "modulate:a", 1.0, 0.15)
	tween.tween_interval(1.1)
	tween.tween_property(toast_panel, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): toast_panel.visible = false)
