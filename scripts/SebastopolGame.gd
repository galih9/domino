class_name SebastopolGame
extends Node2D

## Sebastopol Domino Game Orchestrator (The Star).
## Features:
## - Double-six 28-tile set, authentic 4-player deal (7 tiles each, no boneyard drawing)
## - Opening move: player with [6-6] MUST play it first in center
## - Star rule: all 4 arms (North, South, East, West) MUST have a 6 played before any arm extends
## - Open phase: players match any of the 4 open branches
## - Strategic block game: passing when unable to play, Domino or Blocked victory
## - Match play with customizable targets (50, 100, 150, 200 pts)

enum State {
	SETUP,
	SHUFFLE,
	DEAL,
	DETERMINE_FIRST,
	STAR_OPENING,
	PLAYING,
	ROUND_OVER
}

var current_state: State = State.SETUP
var num_opponents: int = 3 # 3 AI = 4 players total (classic Sebastopol standard)
var match_target: int = 100
var players: Array[Player] = []
var current_player_idx: int = 0
var consecutive_passes: int = 0
var is_instant_mode: bool = false # Enables instant execution for automated tests

var boneyard: Array[DominoTile] = []
var all_tiles: Array[DominoTile] = []

var selected_hand_tile: DominoTile = null
var is_animating: bool = false
var match_over: bool = false

# Preloaded scenes
const TileScene = preload("res://scenes/domino_tile.tscn")

# Node references
@onready var board: SebastopolBoard = $BoardContainer/DominoBoard
@onready var board_container: Node2D = $BoardContainer
@onready var tile_layer: Control = $UICanvas/TileLayer

# UI references
@onready var ui_canvas: CanvasLayer = $UICanvas
@onready var turn_label: Label = $UICanvas/HUD/TopBar/HBox/TurnPill/TurnLabel
@onready var match_target_label: Label = $UICanvas/HUD/TopBar/HBox/TargetPill/TargetLabel
@onready var star_status_label: Label = $UICanvas/HUD/TopBar/HBox/StarPill/StarLabel
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
@onready var human_badge_score: Label = $UICanvas/HumanHandArea/Badge/HBox/ScoreLabel

@onready var top_badge: PanelContainer = $UICanvas/OpponentTopArea/Badge
@onready var top_badge_name: Label = $UICanvas/OpponentTopArea/Badge/HBox/NameLabel
@onready var top_badge_count: Label = $UICanvas/OpponentTopArea/Badge/HBox/CountLabel
@onready var top_badge_score: Label = $UICanvas/OpponentTopArea/Badge/HBox/ScoreLabel

@onready var left_badge: PanelContainer = $UICanvas/OpponentLeftArea/Badge
@onready var left_badge_name: Label = $UICanvas/OpponentLeftArea/Badge/HBox/NameLabel
@onready var left_badge_count: Label = $UICanvas/OpponentLeftArea/Badge/HBox/CountLabel
@onready var left_badge_score: Label = $UICanvas/OpponentLeftArea/Badge/HBox/ScoreLabel

@onready var right_badge: PanelContainer = $UICanvas/OpponentRightArea/Badge
@onready var right_badge_name: Label = $UICanvas/OpponentRightArea/Badge/HBox/NameLabel
@onready var right_badge_count: Label = $UICanvas/OpponentRightArea/Badge/HBox/CountLabel
@onready var right_badge_score: Label = $UICanvas/OpponentRightArea/Badge/HBox/ScoreLabel

# Placement prompt with directional arm buttons
@onready var placement_prompt: Control = $UICanvas/PlacementPrompt
@onready var btn_play_north: Button = $UICanvas/PlacementPrompt/HBox/BtnPlayNorth
@onready var btn_play_south: Button = $UICanvas/PlacementPrompt/HBox/BtnPlaySouth
@onready var btn_play_east: Button = $UICanvas/PlacementPrompt/HBox/BtnPlayEast
@onready var btn_play_west: Button = $UICanvas/PlacementPrompt/HBox/BtnPlayWest
@onready var btn_cancel_prompt: Button = $UICanvas/PlacementPrompt/HBox/BtnCancel

# Game Over Dialog
@onready var game_over_panel: Control = $UICanvas/GameOverDialog
@onready var game_over_box: PanelContainer = $UICanvas/GameOverDialog/Panel
@onready var winner_title: Label = $UICanvas/GameOverDialog/Panel/VBox/Title
@onready var score_details: Label = $UICanvas/GameOverDialog/Panel/VBox/Details
@onready var btn_play_again: Button = $UICanvas/GameOverDialog/Panel/VBox/ButtonsHBox/BtnPlayAgain
@onready var btn_change_settings: Button = $UICanvas/GameOverDialog/Panel/VBox/ButtonsHBox/BtnChangeSettings
@onready var btn_main_menu: Button = $UICanvas/GameOverDialog/Panel/VBox/ButtonsHBox/BtnMainMenu

# Setup Modal Dialog
@onready var setup_modal: Control = $UICanvas/SetupModal
@onready var setup_box: PanelContainer = $UICanvas/SetupModal/Panel
@onready var btn_setup_opp1: Button = $UICanvas/SetupModal/Panel/VBox/OppSection/HBox/BtnOpp1
@onready var btn_setup_opp2: Button = $UICanvas/SetupModal/Panel/VBox/OppSection/HBox/BtnOpp2
@onready var btn_setup_opp3: Button = $UICanvas/SetupModal/Panel/VBox/OppSection/HBox/BtnOpp3
@onready var btn_setup_target_50: Button = $UICanvas/SetupModal/Panel/VBox/TargetSection/HBox/BtnTarget50
@onready var btn_setup_target_100: Button = $UICanvas/SetupModal/Panel/VBox/TargetSection/HBox/BtnTarget100
@onready var btn_setup_target_150: Button = $UICanvas/SetupModal/Panel/VBox/TargetSection/HBox/BtnTarget150
@onready var btn_setup_target_200: Button = $UICanvas/SetupModal/Panel/VBox/TargetSection/HBox/BtnTarget200
@onready var btn_setup_theme_light: Button = $UICanvas/SetupModal/Panel/VBox/ThemeSection/HBox/BtnLight
@onready var btn_setup_theme_dark: Button = $UICanvas/SetupModal/Panel/VBox/ThemeSection/HBox/BtnDark
@onready var btn_setup_theme_ginger: Button = $UICanvas/SetupModal/Panel/VBox/ThemeSection/HBox/BtnGinger
@onready var btn_setup_theme_hearts: Button = $UICanvas/SetupModal/Panel/VBox/ThemeSection/HBox/BtnHearts
@onready var btn_setup_theme_stars: Button = $UICanvas/SetupModal/Panel/VBox/ThemeSection/HBox/BtnStars
@onready var btn_setup_confirm: Button = $UICanvas/SetupModal/Panel/VBox/BtnConfirm
@onready var btn_setup_close: Button = $UICanvas/SetupModal/Panel/VBox/BtnClose

# Toast announcement
@onready var toast_panel: PanelContainer = $UICanvas/ToastPanel
@onready var toast_label: Label = $UICanvas/ToastPanel/ToastLabel

# Badge styles
var _badge_normal_style: StyleBoxFlat
var _badge_active_style: StyleBoxFlat
var _btn_toggle_normal_style: StyleBoxFlat
var _btn_toggle_active_style: StyleBoxFlat

# Board drag and zoom state
var _is_panning: bool = false
var _pan_start_mouse: Vector2 = Vector2.ZERO
var _pan_start_board: Vector2 = Vector2.ZERO

func _ready() -> void:
	_init_styles()
	_setup_ui_signals()

	var vp_size: Vector2 = get_viewport_rect().size
	board_container.position = vp_size * 0.5

	num_opponents = GameSettings.sebastopol_opponents
	match_target = GameSettings.sebastopol_match_target

	# Connect star completion signal from board
	if board != null:
		board.star_completed.connect(_on_star_completed)

	start_new_match()

func _init_styles() -> void:
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

	_btn_toggle_normal_style = StyleBoxFlat.new()
	_btn_toggle_normal_style.bg_color = Color(0.12, 0.16, 0.2, 0.65)
	_btn_toggle_normal_style.border_width_left = 1
	_btn_toggle_normal_style.border_width_top = 1
	_btn_toggle_normal_style.border_width_right = 1
	_btn_toggle_normal_style.border_width_bottom = 1
	_btn_toggle_normal_style.border_color = Color(1.0, 1.0, 1.0, 0.1)
	_btn_toggle_normal_style.corner_radius_top_left = 7
	_btn_toggle_normal_style.corner_radius_top_right = 7
	_btn_toggle_normal_style.corner_radius_bottom_right = 7
	_btn_toggle_normal_style.corner_radius_bottom_left = 7

	_btn_toggle_active_style = StyleBoxFlat.new()
	_btn_toggle_active_style.bg_color = Color(0.2, 0.26, 0.32, 0.95)
	_btn_toggle_active_style.border_width_left = 1
	_btn_toggle_active_style.border_width_top = 1
	_btn_toggle_active_style.border_width_right = 1
	_btn_toggle_active_style.border_width_bottom = 1
	_btn_toggle_active_style.border_color = Color(0.92, 0.8, 0.38, 0.95)
	_btn_toggle_active_style.corner_radius_top_left = 7
	_btn_toggle_active_style.corner_radius_top_right = 7
	_btn_toggle_active_style.corner_radius_bottom_right = 7
	_btn_toggle_active_style.corner_radius_bottom_left = 7

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_MIDDLE:
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
	pass_btn.pressed.connect(_on_pass_clicked)
	new_game_btn.pressed.connect(open_setup_modal)
	menu_btn.pressed.connect(_on_menu_clicked)
	center_view_btn.pressed.connect(reset_board_view)

	btn_play_north.pressed.connect(func(): _commit_player_move("north"))
	btn_play_south.pressed.connect(func(): _commit_player_move("south"))
	btn_play_east.pressed.connect(func(): _commit_player_move("east"))
	btn_play_west.pressed.connect(func(): _commit_player_move("west"))
	btn_cancel_prompt.pressed.connect(_on_cancel_prompt_clicked)

	btn_play_again.pressed.connect(_on_play_again_pressed)
	btn_change_settings.pressed.connect(open_setup_modal)
	btn_main_menu.pressed.connect(_on_menu_clicked)

	# Setup modal signals
	btn_setup_opp1.pressed.connect(func(): _set_setup_opponents(1))
	btn_setup_opp2.pressed.connect(func(): _set_setup_opponents(2))
	btn_setup_opp3.pressed.connect(func(): _set_setup_opponents(3))

	btn_setup_target_50.pressed.connect(func(): _set_setup_target(50))
	btn_setup_target_100.pressed.connect(func(): _set_setup_target(100))
	btn_setup_target_150.pressed.connect(func(): _set_setup_target(150))
	btn_setup_target_200.pressed.connect(func(): _set_setup_target(200))

	btn_setup_theme_light.pressed.connect(func(): _set_setup_theme("Light"))
	btn_setup_theme_dark.pressed.connect(func(): _set_setup_theme("Dark"))
	btn_setup_theme_ginger.pressed.connect(func(): _set_setup_theme("Gingerbread"))
	btn_setup_theme_hearts.pressed.connect(func(): _set_setup_theme("Hearts"))
	btn_setup_theme_stars.pressed.connect(func(): _set_setup_theme("Stars"))

	btn_setup_confirm.pressed.connect(_on_setup_confirmed)
	btn_setup_close.pressed.connect(close_setup_modal)

	pass_btn.visible = false
	placement_prompt.visible = false
	game_over_panel.visible = false
	setup_modal.visible = false
	toast_panel.visible = false

func _on_cancel_prompt_clicked() -> void:
	placement_prompt.visible = false
	selected_hand_tile = null
	turn_label.text = "Your Turn"

func _on_menu_clicked() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_star_completed() -> void:
	star_status_label.text = "★ Star Open"
	star_status_label.modulate = Color(0.95, 0.85, 0.4, 1.0)
	show_toast("★ The Star is Complete! All 4 arms are open! ★")

func open_setup_modal() -> void:
	_update_setup_modal_ui()
	setup_modal.visible = true
	if is_instant_mode:
		setup_modal.modulate.a = 1.0
		setup_box.scale = Vector2.ONE
		return
	setup_modal.modulate.a = 0.0
	setup_box.scale = Vector2(0.95, 0.95)
	var tween: Tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(setup_modal, "modulate:a", 1.0, 0.18)
	tween.tween_property(setup_box, "scale", Vector2.ONE, 0.18)

func close_setup_modal() -> void:
	if is_instant_mode:
		setup_modal.visible = false
		return
	var tween: Tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(setup_modal, "modulate:a", 0.0, 0.14)
	tween.chain().tween_callback(func(): setup_modal.visible = false)

func _set_setup_opponents(count: int) -> void:
	num_opponents = count
	_update_setup_modal_ui()

func _set_setup_target(target: int) -> void:
	match_target = target
	_update_setup_modal_ui()

func _set_setup_theme(theme_name: String) -> void:
	ThemeManager.set_theme(theme_name)
	for t in all_tiles:
		if is_instance_valid(t):
			t.refresh_theme()
	_update_setup_modal_ui()

func _update_setup_modal_ui() -> void:
	_apply_toggle(btn_setup_opp1, num_opponents == 1)
	_apply_toggle(btn_setup_opp2, num_opponents == 2)
	_apply_toggle(btn_setup_opp3, num_opponents == 3)

	_apply_toggle(btn_setup_target_50, match_target == 50)
	_apply_toggle(btn_setup_target_100, match_target == 100)
	_apply_toggle(btn_setup_target_150, match_target == 150)
	_apply_toggle(btn_setup_target_200, match_target == 200)

	var cur_theme: String = ThemeManager.get_theme()
	_apply_toggle(btn_setup_theme_light, cur_theme == "Light")
	_apply_toggle(btn_setup_theme_dark, cur_theme == "Dark")
	_apply_toggle(btn_setup_theme_ginger, cur_theme == "Gingerbread")
	_apply_toggle(btn_setup_theme_hearts, cur_theme == "Hearts")
	_apply_toggle(btn_setup_theme_stars, cur_theme == "Stars")

func _apply_toggle(btn: Button, is_active: bool) -> void:
	if btn == null:
		return
	if is_active:
		btn.add_theme_stylebox_override("normal", _btn_toggle_active_style)
		btn.add_theme_stylebox_override("hover", _btn_toggle_active_style)
		btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	else:
		btn.add_theme_stylebox_override("normal", _btn_toggle_normal_style)
		btn.add_theme_stylebox_override("hover", _btn_toggle_normal_style)
		btn.add_theme_color_override("font_color", Color(0.7, 0.76, 0.84, 0.85))

func _on_setup_confirmed() -> void:
	GameSettings.sebastopol_opponents = num_opponents
	GameSettings.sebastopol_match_target = match_target
	close_setup_modal()
	start_new_match()

func _on_play_again_pressed() -> void:
	game_over_panel.hide()
	if match_over:
		start_new_match()
	else:
		start_new_round()

## Starts an entirely new match (resets all player match scores to 0)
func start_new_match() -> void:
	match_over = false
	match_target = GameSettings.sebastopol_match_target
	num_opponents = GameSettings.sebastopol_opponents
	match_target_label.text = "Goal: %d pts" % match_target

	# Create Players
	players.clear()
	# Player 0: Human
	players.append(Player.new(0, "You", true))

	# AI Players
	var ai_names: Array[String] = ["Alex", "Bob", "Chloe"]
	for i in range(num_opponents):
		var p_name: String = ai_names[i % ai_names.size()]
		players.append(AIPlayer.new(i + 1, p_name))

	start_new_round()

## Starts a new round within the current match
func start_new_round() -> void:
	game_over_panel.hide()
	placement_prompt.hide()
	pass_btn.hide()
	consecutive_passes = 0
	selected_hand_tile = null

	star_status_label.text = "✦ Star Hub"
	star_status_label.modulate = Color(0.85, 0.88, 0.92, 0.9)

	# Reset board & clean up tiles
	_clear_all_tiles()
	board.reset()
	reset_board_view()

	# Clear round hand for each player
	for p in players:
		p.clear_hand()
		p.round_score = 0

	_update_opponent_panels()
	_update_all_player_badges()

	# Generate full Double-Six 28 tile set
	_generate_tiles()

	if is_instant_mode:
		_deal_instantly()
	else:
		start_shuffle_phase()

func _clear_all_tiles() -> void:
	for t in all_tiles:
		if is_instance_valid(t):
			t.queue_free()
	all_tiles.clear()
	boneyard.clear()
	selected_hand_tile = null

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

## Shuffle phase with swirling animation
func start_shuffle_phase() -> void:
	current_state = State.SHUFFLE
	is_animating = true
	turn_label.text = "Shuffling"
	SoundManager.play_shuffle()

	boneyard.shuffle()

	var vp_size: Vector2 = get_viewport_rect().size
	var table_center: Vector2 = vp_size * 0.5
	var max_delay: float = 0.15
	var shuffle_dur: float = 0.6

	for i in range(boneyard.size()):
		var tile: DominoTile = boneyard[i]
		tile.z_index = 10 + i
		var delay: float = randf_range(0.0, max_delay)
		tile.animate_shuffle(table_center, delay, shuffle_dur)

	await get_tree().create_timer(max_delay + shuffle_dur + 0.1).timeout
	start_deal_phase()

## Dealing animation: deals 7 tiles to each player
func start_deal_phase() -> void:
	current_state = State.DEAL
	turn_label.text = "Dealing"

	var tiles_per_player: int = 7

	for round_num in range(tiles_per_player):
		for p_idx in range(players.size()):
			if boneyard.is_empty():
				break
			var player: Player = players[p_idx]
			var tile: DominoTile = boneyard.pop_back()
			player.add_tile(tile)
			_update_all_player_badges()

			var target_pos: Vector2 = _get_player_hand_slot_position(p_idx, round_num, tiles_per_player)
			tile.hand_base_pos = target_pos
			var target_scale: Vector2 = Vector2.ONE if p_idx == 0 else Vector2(0.65, 0.65)
			SoundManager.play_deal()
			tile.animate_to(target_pos, 0.0, target_scale, 0.2, false, 24.0, round_num)
			await get_tree().create_timer(0.05).timeout

	_arrange_all_hands()

	await get_tree().create_timer(0.15).timeout
	# Flip human hand face up
	for tile in players[0].hand:
		tile.flip_to(true, 0.25)
		await get_tree().create_timer(0.05).timeout

	await get_tree().create_timer(0.25).timeout
	_determine_first_turn()

## Instant deal helper for tests and fast re-runs
func _deal_instantly() -> void:
	boneyard.shuffle()
	var tiles_per_player: int = 7

	for round_num in range(tiles_per_player):
		for p_idx in range(players.size()):
			if boneyard.is_empty():
				break
			var player: Player = players[p_idx]
			var tile: DominoTile = boneyard.pop_back()
			player.add_tile(tile)
			tile.hand_base_pos = _get_player_hand_slot_position(p_idx, round_num, tiles_per_player)
			tile.position = tile.hand_base_pos
			tile.scale = Vector2.ONE if p_idx == 0 else Vector2(0.65, 0.65)
			if p_idx == 0:
				tile.set_face_up(true)

	_arrange_all_hands()
	_update_all_player_badges()
	_determine_first_turn_instant()

## Find player holding [6-6] spinner
func _determine_first_turn() -> void:
	current_state = State.DETERMINE_FIRST

	var starter_idx: int = _find_starter_index()
	current_player_idx = starter_idx
	var starter: Player = players[current_player_idx]

	if starter.is_human:
		show_toast("You hold [6-6]! Place it in the center.")
	else:
		show_toast("%s holds [6-6] and starts!" % starter.name)

	await get_tree().create_timer(1.0).timeout
	_arrange_all_hands()
	_update_all_player_badges()
	start_playing_turn()

func _determine_first_turn_instant() -> void:
	current_state = State.PLAYING
	current_player_idx = _find_starter_index()
	_arrange_all_hands()
	_update_all_player_badges()
	if players[current_player_idx].is_human:
		_start_human_turn()

func _find_starter_index() -> int:
	# Sebastopol rule: The player with [6-6] must lead
	for i in range(players.size()):
		for t in players[i].hand:
			if t.top_val == 6 and t.bottom_val == 6:
				return i

	# Fallback (if 6-6 was asleep in <4 player game): highest double or highest tile
	var highest_dbl: DominoTile = null
	var dbl_idx: int = 0
	for i in range(players.size()):
		var p_dbl: DominoTile = players[i].get_highest_double()
		if p_dbl != null and (highest_dbl == null or p_dbl.top_val > highest_dbl.top_val):
			highest_dbl = p_dbl
			dbl_idx = i
	if highest_dbl != null:
		return dbl_idx

	var highest_tile: DominoTile = null
	var tile_idx: int = 0
	for i in range(players.size()):
		var p_tile: DominoTile = players[i].get_highest_tile()
		if p_tile != null and (highest_tile == null or p_tile.pip_sum() > highest_tile.pip_sum()):
			highest_tile = p_tile
			tile_idx = i
	return tile_idx

func start_playing_turn() -> void:
	current_state = State.PLAYING
	is_animating = false
	placement_prompt.hide()
	selected_hand_tile = null

	var current_player: Player = players[current_player_idx]
	_highlight_active_player(current_player_idx)

	if not board.is_star_complete and not board.is_empty():
		star_status_label.text = "Star Arms: %d/4" % board.get_filled_arms_count()

	if current_player.is_human:
		_start_human_turn()
	else:
		_start_ai_turn()

func _start_human_turn() -> void:
	var human: Player = players[0]
	var playable: Array[DominoTile] = human.get_playable_tiles(board)

	for tile in human.hand:
		tile.set_playable(playable.has(tile))

	if playable.size() > 0:
		if board.is_empty():
			turn_label.text = "Play [6-6]"
		elif not board.is_star_complete:
			turn_label.text = "Fill Star (Play a 6)"
		else:
			turn_label.text = "Your Turn"
		pass_btn.visible = false
	else:
		# In Sebastopol, there is no boneyard drawing; blocked player must pass!
		turn_label.text = "No Moves (Pass)"
		pass_btn.visible = true

func _on_tile_clicked(tile: DominoTile) -> void:
	if current_state != State.PLAYING or is_animating:
		return
	if current_player_idx != 0:
		return
	if tile.owner_id != 0 or not tile.is_playable:
		return

	SoundManager.play_click()
	selected_hand_tile = tile

	# Opening 6-6 placement
	if board.is_empty():
		_commit_player_move("center")
		return

	var valid_ends: Array[String] = board.get_valid_ends(tile)
	if valid_ends.size() == 1:
		_commit_player_move(valid_ends[0])
	elif valid_ends.size() > 1:
		_show_placement_prompt(tile, valid_ends)

func _show_placement_prompt(tile: DominoTile, valid_ends: Array[String]) -> void:
	btn_play_north.visible = valid_ends.has("north")
	btn_play_south.visible = valid_ends.has("south")
	btn_play_east.visible = valid_ends.has("east")
	btn_play_west.visible = valid_ends.has("west")

	if btn_play_north.visible:
		btn_play_north.text = "↑ North | %d" % board.get_open_val("north")
	if btn_play_south.visible:
		btn_play_south.text = "↓ South | %d" % board.get_open_val("south")
	if btn_play_east.visible:
		btn_play_east.text = "→ East | %d" % board.get_open_val("east")
	if btn_play_west.visible:
		btn_play_west.text = "← West | %d" % board.get_open_val("west")

	placement_prompt.visible = true
	turn_label.text = "Choose Arm"

func _commit_player_move(arm_choice: String) -> void:
	if selected_hand_tile == null:
		return
	placement_prompt.visible = false
	consecutive_passes = 0
	var tile: DominoTile = selected_hand_tile
	selected_hand_tile = null

	players[0].remove_tile(tile)
	tile.owner_id = -1
	tile.set_playable(false)

	for t in players[0].hand:
		t.set_playable(false)

	_execute_tile_placement(tile, arm_choice)

func _execute_tile_placement(tile: DominoTile, arm_choice: String) -> void:
	is_animating = true
	var place_info: Dictionary = board.place_tile(tile, arm_choice)

	tile.set_face_up(true)

	if is_instant_mode:
		tile.reparent(board, false)
		tile.position = place_info["position"] - tile.size * 0.5
		tile.rotation = place_info["rotation"]
		tile.scale = Vector2.ONE
		tile.is_interactable = false
		tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_arrange_all_hands()
		_update_all_player_badges()
		_check_round_end_or_next_turn()
		return

	var target_pos: Vector2 = board.to_global(place_info["position"]) - tile.size * 0.5
	var target_rot: float = place_info["rotation"]

	tile.animate_to(target_pos, target_rot, Vector2.ONE, 0.35, true)

	await get_tree().create_timer(0.38).timeout

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
	pass_btn.visible = false

	var ai: AIPlayer = players[current_player_idx] as AIPlayer
	turn_label.text = "%s" % ai.name

	if not is_instant_mode:
		await get_tree().create_timer(0.75).timeout

	var move: Dictionary = ai.choose_move(board)

	if not move.is_empty():
		consecutive_passes = 0
		var tile: DominoTile = move["tile"]
		var arm_choice: String = move["end"]
		ai.remove_tile(tile)
		tile.owner_id = -1

		if not is_instant_mode:
			tile.flip_to(true, 0.25)
		_execute_tile_placement(tile, arm_choice)
	else:
		# AI has no valid move; pass
		SoundManager.play_pass()
		show_toast("%s passed" % ai.name)
		consecutive_passes += 1
		if not is_instant_mode:
			await get_tree().create_timer(0.75).timeout
		_check_round_end_or_next_turn()

func _on_pass_clicked() -> void:
	if current_state != State.PLAYING or is_animating or current_player_idx != 0:
		return
	is_animating = true
	pass_btn.visible = false
	SoundManager.play_pass()
	show_toast("You passed")
	consecutive_passes += 1
	if not is_instant_mode:
		await get_tree().create_timer(0.5).timeout
	is_animating = false
	_check_round_end_or_next_turn()

func _check_round_end_or_next_turn() -> void:
	var current_player: Player = players[current_player_idx]

	# 1. Check if current player emptied their hand (Domino!)
	if current_player.hand_size() == 0:
		_end_round_winner(current_player, false)
		return

	# 2. Check if the game is blocked (everyone passed in a full orbit)
	if consecutive_passes >= players.size():
		_end_round_blocked()
		return

	# Next turn
	current_player_idx = (current_player_idx + 1) % players.size()
	start_playing_turn()

func _end_round_winner(winner: Player, _is_blocked: bool) -> void:
	current_state = State.ROUND_OVER

	# Reveal all remaining tiles
	for p in players:
		for t in p.hand:
			t.set_playable(false)
			t.is_interactable = false
			t.flip_to(true, 0.25)

	# Winner scores pip sum of all opponents
	var points_won: int = 0
	for p in players:
		if p != winner:
			points_won += p.get_pip_sum()

	winner.total_score += points_won
	winner.round_score = points_won

	GameSettings.record_sebastopol_round(winner.is_human, points_won)

	_check_match_status_and_display(winner, "Domino! %s emptied their hand." % winner.name)

func _end_round_blocked() -> void:
	current_state = State.ROUND_OVER

	for p in players:
		for t in p.hand:
			t.set_playable(false)
			t.is_interactable = false
			t.flip_to(true, 0.25)

	# In a blocked game, the player with the lowest pip total wins
	var min_pips: int = 999999
	var winner: Player = players[0]
	var is_tie: bool = false

	for p in players:
		var pips: int = p.get_pip_sum()
		if pips < min_pips:
			min_pips = pips
			winner = p
			is_tie = false
		elif pips == min_pips and p != winner:
			is_tie = true

	# Standard block scoring: sum of all opponents' pips minus winner's own pips
	var points_won: int = 0
	for p in players:
		if p != winner:
			points_won += p.get_pip_sum()
	points_won = maxi(0, points_won - winner.get_pip_sum())

	winner.total_score += points_won
	winner.round_score = points_won

	GameSettings.record_sebastopol_round(winner.is_human, points_won)

	_check_match_status_and_display(winner, "Game Blocked! %s wins with lowest pips (%d)." % [winner.name, min_pips])

func _check_match_status_and_display(round_winner: Player, outcome_subtitle: String) -> void:
	_update_all_player_badges()

	# Check if any player has met or exceeded the match target score
	var match_winner: Player = null
	for p in players:
		if p.total_score >= match_target:
			if match_winner == null or p.total_score > match_winner.total_score:
				match_winner = p

	if match_winner != null:
		match_over = true
		GameSettings.record_sebastopol_match(match_winner.is_human)
		if match_winner.is_human:
			SoundManager.play_win()
			winner_title.text = "MATCH VICTORY!"
			winner_title.modulate = Color(0.95, 0.85, 0.35, 1.0)
		else:
			SoundManager.play_chips()
			winner_title.text = "%s Wins the Match!" % match_winner.name
			winner_title.modulate = Color(0.95, 0.85, 0.35, 1.0)
		btn_play_again.text = "New Match"
	else:
		match_over = false
		if round_winner.is_human:
			SoundManager.play_win()
			winner_title.text = "Round Won!"
			winner_title.modulate = Color(0.92, 0.8, 0.38, 1.0)
		else:
			SoundManager.play_chips()
			winner_title.text = "%s Won Round" % round_winner.name
			winner_title.modulate = Color(0.92, 0.8, 0.38, 1.0)
		btn_play_again.text = "Next Round"

	var details_lines: Array[String] = [outcome_subtitle, ""]
	for p in players:
		var pips: int = p.get_pip_sum()
		var round_info: String = "+%d pts" % p.round_score if p == round_winner else "%d pips" % pips
		details_lines.append("%s: %s  |  Total: %d / %d pts" % [p.name, round_info, p.total_score, match_target])

	score_details.text = "\n".join(details_lines)
	_show_game_over()

func _show_game_over() -> void:
	game_over_panel.visible = true
	if is_instant_mode:
		game_over_panel.modulate.a = 1.0
		game_over_box.scale = Vector2.ONE
		return
	game_over_panel.modulate.a = 0.0
	game_over_box.scale = Vector2(0.95, 0.95)
	var tween: Tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(game_over_panel, "modulate:a", 1.0, 0.18)
	tween.tween_property(game_over_box, "scale", Vector2.ONE, 0.18)

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
			if is_instant_mode:
				tile.position = target_pos
				tile.scale = target_scale
			else:
				tile.animate_to(target_pos, 0.0, target_scale, 0.2, false)

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
		# 3 AI opponents (Alex on Left, Bob on Top, Chloe on Right)
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
	human_badge_score.text = "%d pts" % players[0].total_score

	if num_opponents == 1 and players.size() > 1:
		top_badge_name.text = players[1].name
		top_badge_count.text = "%d tiles" % players[1].hand_size()
		top_badge_score.text = "%d pts" % players[1].total_score
	elif num_opponents == 2 and players.size() > 2:
		top_badge_name.text = players[1].name
		top_badge_count.text = "%d tiles" % players[1].hand_size()
		top_badge_score.text = "%d pts" % players[1].total_score
		right_badge_name.text = players[2].name
		right_badge_count.text = "%d tiles" % players[2].hand_size()
		right_badge_score.text = "%d pts" % players[2].total_score
	elif num_opponents == 3 and players.size() > 3:
		left_badge_name.text = players[1].name
		left_badge_count.text = "%d tiles" % players[1].hand_size()
		left_badge_score.text = "%d pts" % players[1].total_score

		top_badge_name.text = players[2].name
		top_badge_count.text = "%d tiles" % players[2].hand_size()
		top_badge_score.text = "%d pts" % players[2].total_score

		right_badge_name.text = players[3].name
		right_badge_count.text = "%d tiles" % players[3].hand_size()
		right_badge_score.text = "%d pts" % players[3].total_score

func _set_badge_active(badge: PanelContainer, is_active: bool) -> void:
	if badge == null or _badge_active_style == null or _badge_normal_style == null:
		return
	badge.add_theme_stylebox_override("panel", _badge_active_style if is_active else _badge_normal_style)

func _highlight_active_player(p_idx: int) -> void:
	_set_badge_active(human_badge, p_idx == 0)

	if num_opponents == 1:
		_set_badge_active(top_badge, p_idx == 1)
	elif num_opponents == 2:
		_set_badge_active(top_badge, p_idx == 1)
		_set_badge_active(right_badge, p_idx == 2)
	elif num_opponents == 3:
		_set_badge_active(left_badge, p_idx == 1)
		_set_badge_active(top_badge, p_idx == 2)
		_set_badge_active(right_badge, p_idx == 3)

## Auto-framing: adjusts board position and zoom so entire 4-way star remains centered and visible
func _update_board_framing() -> void:
	var bounds: Rect2 = board.get_board_bounds()
	if bounds.size == Vector2.ZERO:
		return

	var vp_size: Vector2 = get_viewport_rect().size
	var target_scale: float = 1.0

	var max_span_x: float = maxf(bounds.size.x, 220.0)
	var max_span_y: float = maxf(bounds.size.y, 220.0)

	var margin_x: float = vp_size.x * 0.70
	var margin_y: float = vp_size.y * 0.52

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
	tween.tween_interval(1.2)
	tween.tween_property(toast_panel, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): toast_panel.visible = false)
