extends SceneTree

const HoldemGame = preload("res://scripts/HoldemGame.gd")

func _initialize():
	print("--- BEGINNING TEXAS HOLD'EM GAME TESTS ---")
	await test_holdem_scene_and_dealing()
	await test_holdem_showdown_progression()
	print("--- ALL TEXAS HOLD'EM GAME TESTS PASSED ---")
	quit(0)

func test_holdem_scene_and_dealing() -> void:
	print("[TEST] Loading scenes/holdem.tscn...")
	var holdem_scene: PackedScene = load("res://scenes/holdem.tscn")
	assert(holdem_scene != null, "holdem.tscn should load")

	var game: HoldemGame = holdem_scene.instantiate()
	game.is_instant_mode = true # fast execution
	root.add_child(game)
	await process_frame

	# Check node bindings
	assert(game.table_felt != null, "table_felt should exist")
	assert(game.pot_label != null, "pot_label should exist")
	assert(game.community_container != null, "community_container should exist")
	assert(game.community_container.get_child_count() == 5, "5 community card slots required")
	assert(game.players.size() >= 2, "At least 2 players initialized")

	# Check human player setup
	var human = game.players[0]
	assert(human["is_human"] == true, "Player 0 must be human")
	assert(human["cards"].size() == 2, "Human should have 2 hole cards")
	assert(human["cards"][0].is_face_up == true, "Human cards should be face up")

	# Check AI player setup
	var ai = game.players[1]
	assert(ai["is_human"] == false, "Player 1 must be AI")
	assert(ai["cards"].size() == 2, "AI should have 2 hole cards")
	assert(ai["cards"][0].is_face_up == false, "AI cards should be face down pre-flop")

	# Check Pot has blinds
	assert(game.pot > 0, "Pot should contain blinds")

	# Test player controls exist
	assert(game.btn_fold != null, "btn_fold missing")
	assert(game.btn_check_call != null, "btn_check_call missing")
	assert(game.btn_bet_raise != null, "btn_bet_raise missing")

	# Test Fold
	print("[TEST] Testing Fold flow...")
	game._on_user_fold()
	assert(human["is_folded"] == true, "Human should be marked folded")

	# Cleanup
	game.queue_free()
	await process_frame
	print("[PASS] Texas Hold'em core scene and deal tests passed!")

func test_holdem_showdown_progression() -> void:
	print("[TEST] Testing Flop, Turn, River, and Showdown flow...")
	var holdem_scene: PackedScene = load("res://scenes/holdem.tscn")
	var game: HoldemGame = holdem_scene.instantiate()
	game.is_instant_mode = true
	root.add_child(game)
	await process_frame

	# Deal Flop (3 cards)
	game._deal_community_cards(3)
	assert(game.community_cards.size() == 3, "Flop should have 3 community cards")

	# Deal Turn (1 card)
	game._deal_community_cards(1)
	assert(game.community_cards.size() == 4, "Turn should have 4 community cards")

	# Deal River (1 card)
	game._deal_community_cards(1)
	assert(game.community_cards.size() == 5, "River should have 5 community cards")

	# Showdown
	game._handle_showdown()
	assert(game.showdown_banner.visible == true, "Showdown banner should be displayed")
	assert(game.winner_details_label.text.length() > 0, "Winner details should not be empty")

	game.queue_free()
	await process_frame
	print("[PASS] Flop, Turn, River, and Showdown tests passed!")
