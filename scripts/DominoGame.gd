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

var selected_hand_tile: DominoTile = null
var is_animating: bool = false

# Preloaded scenes
const TileScene = preload("res://scenes/domino_tile.tscn")

# Node references
@onready var board: DominoBoard = $BoardContainer/DominoBoard
@onready var board_container: Node2D = $BoardContainer
@onready var tile_layer: Control = $UICanvas/TileLayer

# UI references
@onready var ui_canvas: CanvasLayer = $UICanvas
@onready var opponent_dialog: OpponentDialog = $UICanvas/OpponentDialog
@onready var turn_label: Label = $UICanvas/HUD/TurnLabel
@onready var boneyard_btn: Button = $UICanvas/HUD/BoneyardPanel/VBox/BoneyardBtn
@onready var boneyard_count_label: Label = $UICanvas/HUD/BoneyardPanel/VBox/CountLabel
@onready var pass_btn: Button = $UICanvas/HUD/PassBtn
@onready var new_game_btn: Button = $UICanvas/HUD/TopBar/HBox/NewGameBtn
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
@onready var winner_title: Label = $UICanvas/GameOverDialog/Panel/VBox/Title
@onready var score_details: Label = $UICanvas/GameOverDialog/Panel/VBox/Details
@onready var btn_play_again: Button = $UICanvas/GameOverDialog/Panel/VBox/BtnPlayAgain
@onready var btn_change_settings: Button = $UICanvas/GameOverDialog/Panel/VBox/BtnChangeSettings

# Toast announcement
@onready var toast_panel: PanelContainer = $UICanvas/ToastPanel
@onready var toast_label: Label = $UICanvas/ToastPanel/ToastLabel

# Boneyard spawn position (bottom-left, above Boneyard panel)
var boneyard_pos: Vector2 = Vector2(84, 480)

# Board drag and zoom state
var _is_panning: bool = false
var _pan_start_mouse: Vector2 = Vector2.ZERO
var _pan_start_board: Vector2 = Vector2.ZERO

func _ready() -> void:
	_setup_ui_signals()
	var vp_size: Vector2 = get_viewport_rect().size
	boneyard_pos = Vector2(84.0, vp_size.y - 200.0)
	board_container.position = vp_size * 0.5

	# Show setup dialog at game start
	show_setup_dialog()

func _unhandled_input(event: InputEvent) -> void:
	# Pan with Right Mouse Button or Middle Mouse Button
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
	opponent_dialog.setup_confirmed.connect(_on_setup_confirmed)
	boneyard_btn.pressed.connect(_on_boneyard_clicked)
	pass_btn.pressed.connect(_on_pass_clicked)
	new_game_btn.pressed.connect(show_setup_dialog)
	center_view_btn.pressed.connect(reset_board_view)

	btn_play_left.pressed.connect(func(): _commit_player_move("left"))
	btn_play_right.pressed.connect(func(): _commit_player_move("right"))
	btn_cancel_prompt.pressed.connect(_on_cancel_prompt_clicked)

	btn_play_again.pressed.connect(_on_play_again_pressed)
	btn_change_settings.pressed.connect(show_setup_dialog)

	pass_btn.visible = false
	placement_prompt.visible = false
	game_over_panel.visible = false
	toast_panel.visible = false

func _on_cancel_prompt_clicked() -> void:
	placement_prompt.visible = false
	selected_hand_tile = null
	turn_label.text = "Your turn! Pick a highlighted domino to play."

func show_setup_dialog() -> void:
	current_state = State.SETUP
	opponent_dialog.show()
	game_over_panel.hide()
	placement_prompt.hide()

func _on_setup_confirmed(opponents: int, theme_name: String) -> void:
	num_opponents = opponents
	ThemeManager.set_theme(theme_name)
	start_new_match()

func _on_play_again_pressed() -> void:
	game_over_panel.hide()
	start_new_match()

func start_new_match() -> void:
	opponent_dialog.hide()
	game_over_panel.hide()
	placement_prompt.hide()

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
		var p_name: String = "AI (%s)" % ai_names[i % ai_names.size()]
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
	# Neat layered stack of dominoes above the Draw Tile button
	var col: int = index % 2
	var row: int = (index / 2) % 7
	var layer: int = index / 14
	var offset: Vector2 = Vector2(col * 24.0 - 12.0, row * 4.0 - 16.0 - layer * 3.0)
	return boneyard_pos + offset - Vector2(28.0, 56.0) * 0.65

func _update_boneyard_stack(duration: float = 0.25) -> void:
	for i in range(boneyard.size()):
		var tile: DominoTile = boneyard[i]
		var target_pos: Vector2 = _get_boneyard_slot_position(i)
		tile.z_index = i
		tile.animate_to(target_pos, 0.0, Vector2(0.65, 0.65), duration, false)

func _generate_tiles() -> void:
	all_tiles.clear()
	boneyard.clear()

	for a in range(7):
		for b in range(a, 7):
			var tile: DominoTile = TileScene.instantiate()
			tile_layer.add_child(tile)
			# Empty tile for back of card, initially face-down
			tile.setup(a, b, false, -1)
			tile.scale = Vector2(0.65, 0.65)
			tile.position = _get_boneyard_slot_position(boneyard.size())
			tile.tile_clicked.connect(_on_tile_clicked)
			all_tiles.append(tile)
			boneyard.append(tile)

	_update_boneyard_count()
	_update_boneyard_stack(0.0)

## Shuffle animation: swirling, spreading and gathering
func start_shuffle_phase() -> void:
	current_state = State.SHUFFLE
	is_animating = true
	turn_label.text = "Shuffling dominoes..."
	if SoundManager.instance:
		SoundManager.instance.play_shuffle()

	# Randomize array order
	boneyard.shuffle()

	# Animate tiles swirling around center table
	var vp_size: Vector2 = get_viewport_rect().size
	var table_center: Vector2 = vp_size * 0.5
	for i in range(boneyard.size()):
		var tile: DominoTile = boneyard[i]
		var delay: float = randf_range(0.0, 0.2)
		tile.animate_shuffle(table_center, delay, 0.6)

	await get_tree().create_timer(0.75).timeout

	# Neat stack into boneyard position (above Boneyard panel, NOT in center of board!)
	_update_boneyard_stack(0.35)

	await get_tree().create_timer(0.4).timeout
	start_deal_phase()

## Dealing animation: dealing tiles to human and AI hands
func start_deal_phase() -> void:
	current_state = State.DEAL
	turn_label.text = "Dealing dominoes..."

	var tiles_per_player: int = 7
	if players.size() == 4:
		tiles_per_player = 6 # 6 tiles each for 4 players leaves 4 in boneyard

	# Round-robin deal
	for round_num in range(tiles_per_player):
		for p_idx in range(players.size()):
			if boneyard.is_empty():
				break
			var player: Player = players[p_idx]
			var tile: DominoTile = boneyard.pop_back()
			player.add_tile(tile)
			_update_boneyard_count()
			_update_all_player_badges()

			if SoundManager.instance:
				SoundManager.instance.play_deal()

			# Animate to player hand position
			var target_pos: Vector2 = _get_player_hand_slot_position(p_idx, player.hand_size() - 1, player.hand_size())
			var target_scale: Vector2 = Vector2.ONE if p_idx == 0 else Vector2(0.65, 0.65)
			tile.animate_to(target_pos, 0.0, target_scale, 0.22, false)
			await get_tree().create_timer(0.06).timeout

	_update_boneyard_stack(0.2)

	# Flip human player's hand face-up sequentially!
	await get_tree().create_timer(0.2).timeout
	var human_hand: Array[DominoTile] = players[0].hand
	for i in range(human_hand.size()):
		var tile: DominoTile = human_hand[i]
		tile.flip_to(true, 0.32)
		await get_tree().create_timer(0.07).timeout

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
		# No doubles, find highest pip tile
		var highest_tile: DominoTile = null
		for i in range(players.size()):
			var p_tile: DominoTile = players[i].get_highest_tile()
			if p_tile != null:
				if highest_tile == null or p_tile.pip_sum() > highest_tile.pip_sum():
					highest_tile = p_tile
					starter_idx = i

	current_player_idx = starter_idx
	var starter: Player = players[current_player_idx]

	if highest_dbl != null:
		show_toast("%s holds [%d|%d] and goes first!" % [starter.name, highest_dbl.top_val, highest_dbl.bottom_val])
	else:
		show_toast("%s holds the highest tile and goes first!" % [starter.name])

	await get_tree().create_timer(1.2).timeout
	_arrange_all_hands()
	_update_all_player_badges()
	start_playing_turn()

func start_playing_turn() -> void:
	current_state = State.PLAYING
	is_animating = false
	placement_prompt.hide()
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

	if playable.size() > 0:
		turn_label.text = "Your turn! Pick a highlighted domino to play."
		pass_btn.visible = false
		boneyard_btn.disabled = true
	else:
		if boneyard.size() > 0:
			turn_label.text = "No playable dominoes! Draw from the boneyard."
			pass_btn.visible = false
			boneyard_btn.disabled = false
		else:
			turn_label.text = "No playable dominoes and boneyard is empty! Pass turn."
			pass_btn.visible = true
			boneyard_btn.disabled = true

func _on_tile_clicked(tile: DominoTile) -> void:
	if current_state != State.PLAYING or is_animating:
		return
	if current_player_idx != 0:
		return # Not human's turn
	if tile.owner_id != 0 or not tile.is_playable:
		return

	selected_hand_tile = tile

	# If board is empty, play as first tile
	if board.is_empty():
		_commit_player_move("first")
		return

	var valid_ends: Array[String] = board.get_valid_ends(tile)
	if valid_ends.size() == 1:
		# Only one valid end, play immediately!
		_commit_player_move(valid_ends[0])
	elif valid_ends.size() > 1:
		# Player can choose left or right end!
		btn_play_left.text = "◀ Connect Left [%d]" % board.open_left_val
		btn_play_right.text = "Connect Right [%d] ▶" % board.open_right_val
		placement_prompt.visible = true
		turn_label.text = "Choose which end of the train to connect to:"

func _commit_player_move(end_choice: String) -> void:
	if selected_hand_tile == null:
		return
	placement_prompt.visible = false
	consecutive_passes = 0
	var tile: DominoTile = selected_hand_tile
	selected_hand_tile = null

	# Remove from hand
	players[0].remove_tile(tile)
	tile.owner_id = -1
	tile.set_playable(false)

	# Turn off glow on all human tiles while placing
	for t in players[0].hand:
		t.set_playable(false)

	_execute_tile_placement(tile, end_choice)

func _execute_tile_placement(tile: DominoTile, end_choice: String) -> void:
	is_animating = true
	var place_info: Dictionary = board.place_tile(tile, end_choice)

	# Ensure the tile is face up
	tile.set_face_up(true)

	# Convert board local position to global position
	var target_pos: Vector2 = board.to_global(place_info["position"]) - tile.size * 0.5
	var target_rot: float = place_info["rotation"]

	# Move animation to board
	tile.animate_to(target_pos, target_rot, Vector2.ONE, 0.38, true)

	await get_tree().create_timer(0.4).timeout

	# Reparent tile to board
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
	# Clear playable highlights on human hand during AI turns
	for tile in players[0].hand:
		tile.set_playable(false)
	boneyard_btn.disabled = true
	pass_btn.visible = false

	var ai: AIPlayer = players[current_player_idx] as AIPlayer
	turn_label.text = "%s is thinking..." % ai.name

	await get_tree().create_timer(0.85).timeout

	var move: Dictionary = ai.choose_move(board)

	if not move.is_empty():
		consecutive_passes = 0
		var tile: DominoTile = move["tile"]
		var end_choice: String = move["end"]
		ai.remove_tile(tile)
		tile.owner_id = -1

		# Flip face up as it moves onto board
		tile.flip_to(true, 0.28)
		_execute_tile_placement(tile, end_choice)
	else:
		# No move possible, try drawing from boneyard
		if boneyard.size() > 0:
			_ai_draw_tile(ai)
		else:
			# Pass turn
			show_toast("%s passes!" % ai.name)
			if SoundManager.instance:
				SoundManager.instance.play_pass()
			consecutive_passes += 1
			await get_tree().create_timer(0.8).timeout
			_check_round_end_or_next_turn()

func _ai_draw_tile(ai: AIPlayer) -> void:
	var tile: DominoTile = boneyard.pop_back()
	ai.add_tile(tile)
	_update_boneyard_count()
	_update_boneyard_stack()
	_update_all_player_badges()

	show_toast("%s drew from the boneyard." % ai.name)
	if SoundManager.instance:
		SoundManager.instance.play_draw()

	var target_pos: Vector2 = _get_player_hand_slot_position(current_player_idx, ai.hand_size() - 1, ai.hand_size())
	tile.animate_to(target_pos, 0.0, Vector2(0.65, 0.65), 0.25, false)

	await get_tree().create_timer(0.4).timeout
	_arrange_all_hands()

	# Re-check if AI can play the newly drawn tile
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
		# Check if can draw again or must pass
		if boneyard.size() > 0:
			await get_tree().create_timer(0.4).timeout
			_ai_draw_tile(ai)
		else:
			show_toast("%s has no moves and passes." % ai.name)
			if SoundManager.instance:
				SoundManager.instance.play_pass()
			consecutive_passes += 1
			await get_tree().create_timer(0.8).timeout
			_check_round_end_or_next_turn()

func _on_boneyard_clicked() -> void:
	if current_state != State.PLAYING or is_animating:
		return
	if current_player_idx != 0:
		return # Not player turn
	if boneyard.is_empty():
		return

	var human: Player = players[0]
	if human.has_playable(board):
		turn_label.text = "You already have playable dominoes in hand!"
		return

	is_animating = true

	# Draw tile
	var tile: DominoTile = boneyard.pop_back()
	human.add_tile(tile)
	_update_boneyard_count()
	_update_boneyard_stack()
	_update_all_player_badges()

	if SoundManager.instance:
		SoundManager.instance.play_draw()

	var target_pos: Vector2 = _get_player_hand_slot_position(0, human.hand_size() - 1, human.hand_size())
	tile.animate_to(target_pos, 0.0, Vector2.ONE, 0.28, false)

	await get_tree().create_timer(0.3).timeout
	tile.flip_to(true, 0.32)
	await get_tree().create_timer(0.25).timeout

	_arrange_all_hands()
	is_animating = false
	_start_human_turn()

func _on_pass_clicked() -> void:
	if current_state != State.PLAYING or is_animating or current_player_idx != 0:
		return
	is_animating = true
	pass_btn.visible = false
	show_toast("You passed!")
	if SoundManager.instance:
		SoundManager.instance.play_pass()
	consecutive_passes += 1
	await get_tree().create_timer(0.6).timeout
	is_animating = false
	_check_round_end_or_next_turn()

func _check_round_end_or_next_turn() -> void:
	# Condition 1: Domino! (Current player has 0 tiles)
	var current_player: Player = players[current_player_idx]
	if current_player.hand_size() == 0:
		_end_round_winner(current_player, false)
		return

	# Condition 2: Blocked game (all players passed in succession and boneyard empty)
	if consecutive_passes >= players.size() and boneyard.is_empty():
		_end_round_blocked()
		return

	# Continue to next turn
	current_player_idx = (current_player_idx + 1) % players.size()
	start_playing_turn()

func _end_round_winner(winner: Player, is_blocked: bool) -> void:
	current_state = State.ROUND_OVER
	if SoundManager.instance:
		SoundManager.instance.play_win()

	# Flip all remaining opponent tiles face-up so player can see them!
	for p in players:
		for t in p.hand:
			t.set_playable(false)
			t.is_interactable = false
			t.flip_to(true, 0.25)

	# Calculate points
	var points_won: int = 0
	var details_text: String = ""

	for p in players:
		var pips: int = p.get_pip_sum()
		if p != winner:
			points_won += pips
		details_text += "%s: %d tiles (%d pips)\n" % [p.name, p.hand_size(), pips]

	winner.round_score += points_won

	if winner.is_human:
		winner_title.text = "🎉 DOMINO! YOU WON! 🎉"
		winner_title.modulate = Color(0.3, 1.0, 0.5, 1.0)
	else:
		winner_title.text = "%s Won the Round!" % winner.name
		winner_title.modulate = Color(1.0, 0.85, 0.3, 1.0)

	score_details.text = details_text + "\nPoints won: +%d points!" % points_won
	game_over_panel.visible = true

func _end_round_blocked() -> void:
	current_state = State.ROUND_OVER
	if SoundManager.instance:
		SoundManager.instance.play_win()

	for p in players:
		for t in p.hand:
			t.set_playable(false)
			t.is_interactable = false
			t.flip_to(true, 0.25)

	# Lowest pip sum wins
	var min_pips: int = 99999
	var winner: Player = players[0]
	var details_text: String = "Game Blocked! Pip counts:\n\n"

	for p in players:
		var pips: int = p.get_pip_sum()
		details_text += "%s: %d tiles, %d pips\n" % [p.name, p.hand_size(), pips]
		if pips < min_pips:
			min_pips = pips
			winner = p

	var points_won: int = 0
	for p in players:
		if p != winner:
			points_won += p.get_pip_sum()

	winner.round_score += points_won

	if winner.is_human:
		winner_title.text = "🎉 GAME BLOCKED! YOU HAVE LOWEST PIPS! 🎉"
		winner_title.modulate = Color(0.3, 1.0, 0.5, 1.0)
	else:
		winner_title.text = "Game Blocked! %s Wins!" % winner.name
		winner_title.modulate = Color(1.0, 0.85, 0.3, 1.0)

	score_details.text = details_text + "\nPoints won: +%d points!" % points_won
	game_over_panel.visible = true

## Updates boneyard counter UI
func _update_boneyard_count() -> void:
	boneyard_count_label.text = "Boneyard: %d" % boneyard.size()
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
		# Human Hand (Bottom Center)
		var tile_w: float = 56.0
		var max_tray_width: float = vp_size.x - 340.0
		var spacing: float = 6.0
		if total_tiles > 1:
			spacing = clampf((max_tray_width - total_tiles * tile_w) / float(total_tiles - 1), -18.0, 6.0)

		var total_width: float = total_tiles * tile_w + (total_tiles - 1) * spacing
		var start_x: float = (vp_size.x - total_width) * 0.5
		var y: float = vp_size.y - 128.0
		return Vector2(start_x + tile_index * (tile_w + spacing), y)

	# Opponents layout based on opponent count
	if num_opponents == 1:
		# Single opponent: Top Center
		var tile_w: float = 38.0
		var spacing: float = 4.0
		if total_tiles > 1:
			spacing = clampf((480.0 - total_tiles * tile_w) / float(total_tiles - 1), -14.0, 4.0)
		var total_w: float = total_tiles * tile_w + (total_tiles - 1) * spacing
		var start_x: float = (vp_size.x - total_w) * 0.5
		return Vector2(start_x + tile_index * (tile_w + spacing), 65.0)

	elif num_opponents == 2:
		# 2 Opponents: P1 Top Left, P2 Top Right
		var tile_w: float = 34.0
		var spacing: float = 2.0
		if player_idx == 1:
			var start_x: float = 180.0
			return Vector2(start_x + tile_index * (tile_w + spacing), 65.0)
		else:
			var start_x: float = vp_size.x - 380.0
			return Vector2(start_x + tile_index * (tile_w + spacing), 65.0)

	else:
		# 3 Opponents: P1 Left, P2 Top Center, P3 Right
		if player_idx == 1:
			# Left
			return Vector2(36.0, 160.0 + tile_index * 36.0)
		elif player_idx == 2:
			# Top
			var tile_w: float = 34.0
			var total_w: float = total_tiles * tile_w
			var start_x: float = (vp_size.x - total_w) * 0.5
			return Vector2(start_x + tile_index * 34.0, 65.0)
		else:
			# Right
			return Vector2(vp_size.x - 80.0, 160.0 + tile_index * 36.0)

	return Vector2.ZERO

func _update_opponent_panels() -> void:
	opponent_top_container.visible = true
	opponent_left_container.visible = (num_opponents >= 3)
	opponent_right_container.visible = (num_opponents >= 2)

func _update_all_player_badges() -> void:
	if players.is_empty():
		return

	# Human player pips
	human_badge_pips.text = "(%d pips)" % players[0].get_pip_sum()

	# Opponent 1 (Top)
	if players.size() > 1:
		top_badge_name.text = "🤖 " + players[1].name
		top_badge_count.text = "🁢 %d" % players[1].hand_size()

	# Opponent 2 (Right or Left)
	if num_opponents == 2 and players.size() > 2:
		right_badge_name.text = "🤖 " + players[2].name
		right_badge_count.text = "🁢 %d" % players[2].hand_size()
	elif num_opponents == 3 and players.size() > 3:
		left_badge_name.text = "🤖 " + players[2].name
		left_badge_count.text = "🁢 %d" % players[2].hand_size()
		right_badge_name.text = "🤖 " + players[3].name
		right_badge_count.text = "🁢 %d" % players[3].hand_size()

func _highlight_active_player(p_idx: int) -> void:
	human_badge.modulate = Color(1.3, 1.3, 0.9, 1.0) if p_idx == 0 else Color(1, 1, 1, 0.8)
	top_badge.modulate = Color(1.3, 1.3, 0.9, 1.0) if p_idx == 1 else Color(1, 1, 1, 0.8)
	if num_opponents == 2:
		right_badge.modulate = Color(1.3, 1.3, 0.9, 1.0) if p_idx == 2 else Color(1, 1, 1, 0.8)
	elif num_opponents == 3:
		left_badge.modulate = Color(1.3, 1.3, 0.9, 1.0) if p_idx == 2 else Color(1, 1, 1, 0.8)
		right_badge.modulate = Color(1.3, 1.3, 0.9, 1.0) if p_idx == 3 else Color(1, 1, 1, 0.8)

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
	tween.tween_property(toast_panel, "modulate:a", 1.0, 0.2)
	tween.tween_interval(1.4)
	tween.tween_property(toast_panel, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): toast_panel.visible = false)
