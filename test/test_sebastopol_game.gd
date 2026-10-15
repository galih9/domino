extends SceneTree

const SebastopolGame = preload("res://scripts/SebastopolGame.gd")
const SebastopolBoard = preload("res://scripts/SebastopolBoard.gd")
const DominoTile = preload("res://scripts/DominoTile.gd")
const TileScene = preload("res://scenes/domino_tile.tscn")

func _initialize() -> void:
	print("--- BEGINNING SEBASTOPOL DOMINO TESTS ---")
	await test_sebastopol_board_rules()
	await test_sebastopol_game_scene()
	print("--- ALL SEBASTOPOL DOMINO TESTS PASSED ---")
	quit(0)

func test_sebastopol_board_rules() -> void:
	print("[TEST] Testing SebastopolBoard core rules & 4-way star mechanics...")
	var board := SebastopolBoard.new()
	root.add_child(board)
	await process_frame

	# 1. Initial State
	assert(board.is_empty() == true, "Board must start empty")
	assert(board.is_star_complete == false, "Star should not be complete initially")
	assert(board.get_filled_arms_count() == 0, "No arms should be filled initially")
	assert(board.get_empty_arms().size() == 4, "All 4 arms should start empty")

	# Create test tiles
	var tile_6_6: DominoTile = TileScene.instantiate()
	tile_6_6.setup(6, 6, true)
	var tile_6_5: DominoTile = TileScene.instantiate()
	tile_6_5.setup(6, 5, true)
	var tile_6_4: DominoTile = TileScene.instantiate()
	tile_6_4.setup(6, 4, true)
	var tile_6_3: DominoTile = TileScene.instantiate()
	tile_6_3.setup(6, 3, true)
	var tile_6_2: DominoTile = TileScene.instantiate()
	tile_6_2.setup(6, 2, true)
	var tile_5_2: DominoTile = TileScene.instantiate()
	tile_5_2.setup(5, 2, true)
	var tile_4_1: DominoTile = TileScene.instantiate()
	tile_4_1.setup(4, 1, true)

	# 2. Opening Rule: ONLY [6-6] can open the board
	assert(board.can_play(tile_6_6) == true, "[6-6] must be valid to open the board")
	assert(board.can_play(tile_6_5) == false, "Non-double-six [6-5] cannot open empty board")
	assert(board.can_play(tile_5_2) == false, "Non-double-six [5-2] cannot open empty board")
	assert(board.get_valid_ends(tile_6_6) == ["center"], "Opening move valid end should be center")

	# Place [6-6] in center
	var p_center: Dictionary = board.place_tile(tile_6_6, "center")
	assert(p_center["position"] == Vector2.ZERO, "Center tile must be at (0, 0)")
	assert(board.spinner_tile == tile_6_6, "Spinner tile must be set")
	assert(board.is_empty() == false, "Board is no longer empty")
	assert(board.is_star_complete == false, "Star is not complete with only spinner")
	for arm in ["north", "south", "east", "west"]:
		assert(board.get_open_val(arm) == 6, "Arm %s must require a 6" % arm)

	# 3. Star Phase: Can only play on EMPTY arms of the star, matching 6
	assert(board.can_play(tile_6_5) == true, "[6-5] has a 6, so can play on star")
	assert(board.can_play(tile_5_2) == false, "[5-2] has no 6, cannot play during star phase")
	var valid_ends_6_5: Array[String] = board.get_valid_ends(tile_6_5)
	assert(valid_ends_6_5.size() == 4, "Expected 4 empty arms available for [6-5]")

	# Place [6-5] on North arm
	board.place_tile(tile_6_5, "north")
	assert(board.get_filled_arms_count() == 1, "1 arm filled")
	assert(board.get_open_val("north") == 5, "North open value is now 5")
	assert(board.is_star_complete == false, "Star still not complete")

	# Crucial Rule Test: Cannot extend North arm to a 2nd tile before all 4 arms are filled!
	assert(board.can_play(tile_5_2) == false, "[5-2] cannot play on North(5) because star is not complete!")
	var valid_ends_6_4: Array[String] = board.get_valid_ends(tile_6_4)
	assert(not valid_ends_6_4.has("north"), "North arm is already filled; cannot play 6-4 on North!")
	assert(valid_ends_6_4.has("south") and valid_ends_6_4.has("east") and valid_ends_6_4.has("west"),
		"Remaining empty arms must be south, east, west")

	# Place 2nd arm (South)
	board.place_tile(tile_6_4, "south")
	assert(board.get_filled_arms_count() == 2, "2 arms filled")
	assert(board.get_open_val("south") == 4, "South open value is now 4")

	# Place 3rd arm (East)
	board.place_tile(tile_6_3, "east")
	assert(board.get_filled_arms_count() == 3, "3 arms filled")
	assert(board.get_open_val("east") == 3, "East open value is now 3")
	assert(board.get_empty_arms() == ["west"], "Only west arm should remain empty")

	# Place 4th arm (West) -> Star completion!
	var star_sig: Array[bool] = [false]
	board.star_completed.connect(func(): star_sig[0] = true)
	board.place_tile(tile_6_2, "west")
	assert(board.get_filled_arms_count() == 4, "All 4 arms filled")
	assert(board.get_open_val("west") == 2, "West open value is now 2")
	assert(board.is_star_complete == true, "Star must now be marked complete!")
	assert(star_sig[0] == true, "star_completed signal must be emitted")

	# 4. Open Play Phase: Any open branch can now be extended
	# North is 5, South is 4, East is 3, West is 2
	assert(board.can_play(tile_5_2) == true, "[5-2] can now play on North(5) or West(2)!")
	var ends_5_2: Array[String] = board.get_valid_ends(tile_5_2)
	assert(ends_5_2.has("north") and ends_5_2.has("west"), "Valid ends for [5-2] should be north and west")

	assert(board.can_play(tile_4_1) == true, "[4-1] can play on South(4)")
	var ends_4_1: Array[String] = board.get_valid_ends(tile_4_1)
	assert(ends_4_1 == ["south"], "Valid end for [4-1] should be south")

	# Place tile [4-1] on South arm
	board.place_tile(tile_4_1, "south")
	assert(board.get_open_val("south") == 1, "South open value updated to 1")

	# 5. Undo verification
	assert(board.can_undo() == true, "Undo should be available")
	var undone: DominoTile = board.undo_last_placement()
	assert(undone == tile_4_1, "Undone tile should be tile_4_1")
	assert(board.get_open_val("south") == 4, "South open value restored to 4 after undo")

	# Cleanup test nodes
	tile_6_6.queue_free()
	tile_6_5.queue_free()
	tile_6_4.queue_free()
	tile_6_3.queue_free()
	tile_6_2.queue_free()
	tile_5_2.queue_free()
	tile_4_1.queue_free()
	board.queue_free()
	await process_frame
	print("[PASS] SebastopolBoard core rules passed!")

func test_sebastopol_game_scene() -> void:
	print("[TEST] Testing SebastopolGame Scene & Match Flow...")
	var scene: PackedScene = load("res://scenes/sebastopol.tscn")
	assert(scene != null, "Failed to load scenes/sebastopol.tscn")

	var game: SebastopolGame = scene.instantiate()
	game.is_instant_mode = true
	root.add_child(game)
	await process_frame

	# 1. UI Node assertions
	assert(game.board != null, "board missing")
	assert(game.turn_label != null, "turn_label missing")
	assert(game.match_target_label != null, "match_target_label missing")
	assert(game.star_status_label != null, "star_status_label missing")
	assert(game.pass_btn != null, "pass_btn missing")
	assert(game.new_game_btn != null, "new_game_btn missing")
	assert(game.menu_btn != null, "menu_btn missing")
	assert(game.center_view_btn != null, "center_view_btn missing")
	assert(game.placement_prompt != null, "placement_prompt missing")
	assert(game.btn_play_north != null, "btn_play_north missing")
	assert(game.btn_play_south != null, "btn_play_south missing")
	assert(game.btn_play_east != null, "btn_play_east missing")
	assert(game.btn_play_west != null, "btn_play_west missing")
	assert(game.setup_modal != null, "setup_modal missing")
	assert(game.game_over_panel != null, "game_over_panel missing")

	# 2. Player count and deal verification (4 players total: Human + 3 AI)
	assert(game.players.size() == 4, "Expected 4 players in standard Sebastopol, got %d" % game.players.size())
	assert(game.players[0].is_human == true, "Player 0 must be human")
	assert(game.players[1].name == "Alex", "Player 1 name")
	assert(game.players[2].name == "Bob", "Player 2 name")
	assert(game.players[3].name == "Chloe", "Player 3 name")

	# In 4-player Sebastopol, all 28 tiles are dealt (7 to each player, 0 in boneyard)
	var total_dealt: int = 0
	for p in game.players:
		assert(p.hand_size() == 7, "Each player must have 7 tiles")
		total_dealt += p.hand_size()
	assert(total_dealt == 28, "All 28 double-six tiles must be dealt")
	assert(game.boneyard.is_empty() == true, "Boneyard must be empty in 4-player Sebastopol")

	# 3. Double-six [6-6] starter verification
	var starter_idx: int = game.current_player_idx
	var starter: Player = game.players[starter_idx]
	var has_6_6: bool = false
	for t in starter.hand:
		if t.top_val == 6 and t.bottom_val == 6:
			has_6_6 = true
			break
	assert(has_6_6 == true, "Starter (%s) must hold [6-6]" % starter.name)

	# 4. First turn execution: starter plays [6-6] to center
	if starter.is_human:
		for t in starter.hand:
			if t.top_val == 6 and t.bottom_val == 6:
				game._on_tile_clicked(t)
				break
	else:
		game._start_ai_turn()

	assert(game.board.is_empty() == false, "Board should have center spinner placed")
	assert(game.board.spinner_tile.top_val == 6 and game.board.spinner_tile.bottom_val == 6, "Center must be [6-6]")

	# 5. Test passing flow
	var prev_board_count: int = game.board.placed_tiles.size()
	game.current_state = SebastopolGame.State.PLAYING
	game.current_player_idx = 0
	game._on_pass_clicked()
	assert(game.board.placed_tiles.size() > prev_board_count or game.consecutive_passes >= 1,
		"Passing flow should progress game (either AI plays or pass count increases)")

	# 6. Test Domino victory scoring
	var winner: Player = game.players[0]
	# Clear winner's hand
	winner.clear_hand()
	game._end_round_winner(winner, false)
	assert(game.current_state == SebastopolGame.State.ROUND_OVER, "State should be ROUND_OVER")
	assert(winner.round_score > 0, "Winner must receive points from opponents' pips")
	assert(game.game_over_panel.visible == true, "GameOver panel should be displayed")

	# 7. Test Setup Modal
	game.open_setup_modal()
	assert(game.setup_modal.visible == true, "Setup modal should be visible")
	game._set_setup_opponents(2)
	assert(game.num_opponents == 2, "Opponents updated to 2")
	game._set_setup_target(150)
	assert(game.match_target == 150, "Match target updated to 150")
	game.close_setup_modal()
	assert(game.setup_modal.visible == false, "Setup modal should close")

	game.queue_free()
	await process_frame
	print("[PASS] SebastopolGame Scene & Match Flow passed!")
