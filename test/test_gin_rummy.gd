extends SceneTree

const GinRummyEvaluator = preload("res://scripts/GinRummyEvaluator.gd")
const GinRummyGame = preload("res://scripts/GinRummyGame.gd")
const GinRummyCard = preload("res://scripts/GinRummyCard.gd")

func _initialize() -> void:
	print("--- TESTING GIN RUMMY EVALUATOR & LOGIC ---")
	test_card_values()
	test_sets()
	test_runs()
	test_optimal_partition_and_gin()
	test_discard_evaluation()
	test_layoffs()
	test_showdown_scoring()
	await test_gin_rummy_scene()
	print("--- GIN RUMMY LOGIC TESTS PASSED ---")
	quit(0)

func test_card_values() -> void:
	assert(GinRummyEvaluator.get_card_deadwood_value(1) == 1, "Ace should be 1 point")
	assert(GinRummyEvaluator.get_card_deadwood_value(5) == 5, "5 should be 5 points")
	assert(GinRummyEvaluator.get_card_deadwood_value(9) == 9, "9 should be 9 points")
	assert(GinRummyEvaluator.get_card_deadwood_value(10) == 10, "10 should be 10 points")
	assert(GinRummyEvaluator.get_card_deadwood_value(11) == 10, "Jack should be 10 points")
	assert(GinRummyEvaluator.get_card_deadwood_value(12) == 10, "Queen should be 10 points")
	assert(GinRummyEvaluator.get_card_deadwood_value(13) == 10, "King should be 10 points")

func test_sets() -> void:
	var set3 = [
		{"suit": "Hearts", "rank": 7},
		{"suit": "Spades", "rank": 7},
		{"suit": "Diamonds", "rank": 7}
	]
	assert(GinRummyEvaluator.is_valid_set(set3), "3 sevens should be a valid set")

	var set4 = [
		{"suit": "Hearts", "rank": 11},
		{"suit": "Spades", "rank": 11},
		{"suit": "Diamonds", "rank": 11},
		{"suit": "Clubs", "rank": 11}
	]
	assert(GinRummyEvaluator.is_valid_set(set4), "4 jacks should be a valid set")

	var invalid_set_dupe_suit = [
		{"suit": "Hearts", "rank": 7},
		{"suit": "Hearts", "rank": 7},
		{"suit": "Diamonds", "rank": 7}
	]
	assert(not GinRummyEvaluator.is_valid_set(invalid_set_dupe_suit), "Duplicate suit invalidates set")

	var invalid_set_size = [
		{"suit": "Hearts", "rank": 7},
		{"suit": "Diamonds", "rank": 7}
	]
	assert(not GinRummyEvaluator.is_valid_set(invalid_set_size), "2 cards cannot be a set")

func test_runs() -> void:
	var run3 = [
		{"suit": "Clubs", "rank": 1},
		{"suit": "Clubs", "rank": 2},
		{"suit": "Clubs", "rank": 3}
	]
	assert(GinRummyEvaluator.is_valid_run(run3), "A-2-3 of Clubs should be a valid run")

	var run4 = [
		{"suit": "Spades", "rank": 10},
		{"suit": "Spades", "rank": 11},
		{"suit": "Spades", "rank": 12},
		{"suit": "Spades", "rank": 13}
	]
	assert(GinRummyEvaluator.is_valid_run(run4), "10-J-Q-K of Spades should be a valid run")

	var invalid_run_suit = [
		{"suit": "Clubs", "rank": 4},
		{"suit": "Hearts", "rank": 5},
		{"suit": "Clubs", "rank": 6}
	]
	assert(not GinRummyEvaluator.is_valid_run(invalid_run_suit), "Mixed suits invalidates run")

	var invalid_run_gap = [
		{"suit": "Clubs", "rank": 4},
		{"suit": "Clubs", "rank": 6},
		{"suit": "Clubs", "rank": 7}
	]
	assert(not GinRummyEvaluator.is_valid_run(invalid_run_gap), "Gap in ranks invalidates run")

func test_optimal_partition_and_gin() -> void:
	# Hand with 10 cards forming complete Gin (two runs of 3, one set of 4)
	var gin_hand = [
		{"suit": "Hearts", "rank": 2},
		{"suit": "Hearts", "rank": 3},
		{"suit": "Hearts", "rank": 4},
		{"suit": "Spades", "rank": 9},
		{"suit": "Spades", "rank": 10},
		{"suit": "Spades", "rank": 11},
		{"suit": "Diamonds", "rank": 6},
		{"suit": "Clubs", "rank": 6},
		{"suit": "Hearts", "rank": 6},
		{"suit": "Spades", "rank": 6}
	]
	var part = GinRummyEvaluator.find_optimal_partition(gin_hand)
	assert(part["deadwood_points"] == 0, "Gin hand should have 0 deadwood, got %d" % part["deadwood_points"])
	assert(part["melds"].size() == 3, "Expected 3 melds in complete gin hand")
	assert(part["deadwood"].size() == 0, "No deadwood cards in gin")

	# Hand with some deadwood
	var partial_hand = [
		{"suit": "Hearts", "rank": 5},
		{"suit": "Hearts", "rank": 6},
		{"suit": "Hearts", "rank": 7}, # run of 3
		{"suit": "Spades", "rank": 8},
		{"suit": "Clubs", "rank": 8},
		{"suit": "Diamonds", "rank": 8}, # set of 3
		{"suit": "Spades", "rank": 1},  # deadwood: Ace (1 pt)
		{"suit": "Diamonds", "rank": 3},# deadwood: 3 (3 pts)
		{"suit": "Clubs", "rank": 2},   # deadwood: 2 (2 pts)
		{"suit": "Hearts", "rank": 13}  # deadwood: King (10 pts)
	]
	var part2 = GinRummyEvaluator.find_optimal_partition(partial_hand)
	assert(part2["melds"].size() == 2, "Expected 2 melds")
	assert(part2["deadwood_points"] == 16, "Deadwood points should be 1 + 3 + 2 + 10 = 16, got %d" % part2["deadwood_points"])

func test_discard_evaluation() -> void:
	# 11 cards: 10 form gin if we discard the King of Hearts
	var hand_11 = [
		{"suit": "Hearts", "rank": 2},
		{"suit": "Hearts", "rank": 3},
		{"suit": "Hearts", "rank": 4},
		{"suit": "Spades", "rank": 9},
		{"suit": "Spades", "rank": 10},
		{"suit": "Spades", "rank": 11},
		{"suit": "Diamonds", "rank": 6},
		{"suit": "Clubs", "rank": 6},
		{"suit": "Hearts", "rank": 6},
		{"suit": "Spades", "rank": 6},
		{"suit": "Hearts", "rank": 13} # extraneous King
	]
	var res = GinRummyEvaluator.evaluate_best_discard(hand_11)
	assert(res["lowest_deadwood"] == 0, "Best discard should produce 0 deadwood (GIN)")
	assert(res["best_card"]["rank"] == 13, "Best card to discard should be the King")

func test_layoffs() -> void:
	var knocker_melds = [
		[
			{"suit": "Hearts", "rank": 4},
			{"suit": "Hearts", "rank": 5},
			{"suit": "Hearts", "rank": 6}
		],
		[
			{"suit": "Spades", "rank": 8},
			{"suit": "Diamonds", "rank": 8},
			{"suit": "Clubs", "rank": 8}
		]
	]
	# Defender has 7 of Hearts (extends run) and 8 of Hearts (completes 4-of-a-kind set) and King of Spades (deadwood)
	var defender_deadwood = [
		{"suit": "Hearts", "rank": 7},
		{"suit": "Hearts", "rank": 8},
		{"suit": "Spades", "rank": 13}
	]
	var layoff_res = GinRummyEvaluator.calculate_layoffs(knocker_melds, defender_deadwood)
	assert(layoff_res["laid_off_cards"].size() == 2, "Defender should be able to lay off 2 cards, got %d" % layoff_res["laid_off_cards"].size())
	assert(layoff_res["deadwood_points"] == 10, "Remaining deadwood points should be 10 (King)")

func test_showdown_scoring() -> void:
	# Case 1: Gin
	var knocker_gin = [
		{"suit": "Hearts", "rank": 2}, {"suit": "Hearts", "rank": 3}, {"suit": "Hearts", "rank": 4},
		{"suit": "Spades", "rank": 9}, {"suit": "Spades", "rank": 10}, {"suit": "Spades", "rank": 11},
		{"suit": "Diamonds", "rank": 6}, {"suit": "Clubs", "rank": 6}, {"suit": "Hearts", "rank": 6}, {"suit": "Spades", "rank": 6}
	]
	var defender_dw15 = [
		{"suit": "Clubs", "rank": 1}, {"suit": "Clubs", "rank": 2}, {"suit": "Clubs", "rank": 3},
		{"suit": "Spades", "rank": 1}, {"suit": "Spades", "rank": 2}, {"suit": "Spades", "rank": 3},
		{"suit": "Diamonds", "rank": 5}, {"suit": "Diamonds", "rank": 10}, # 5+10 = 15 deadwood
		{"suit": "Hearts", "rank": 12}, {"suit": "Diamonds", "rank": 12} # not a set (only 2 cards) -> +10 +10 = 35 total dw
	]
	var res1 = GinRummyEvaluator.evaluate_showdown(knocker_gin, defender_dw15)
	assert(res1["winner"] == "knocker", "Knocker with GIN must win")
	assert(res1["is_gin"] == true, "Should be flagged as Gin")
	assert(res1["points_awarded"] == 25 + res1["defender_deadwood_before"], "Gin gives 25 + defender deadwood")

	# Case 2: Undercut
	var knocker_undercut = [
		{"suit": "Hearts", "rank": 7}, {"suit": "Spades", "rank": 7}, {"suit": "Diamonds", "rank": 7},
		{"suit": "Hearts", "rank": 8}, {"suit": "Spades", "rank": 8}, {"suit": "Diamonds", "rank": 8},
		{"suit": "Spades", "rank": 5}, # deadwood 5 pts
		{"suit": "Clubs", "rank": 2}, {"suit": "Clubs", "rank": 3}, {"suit": "Clubs", "rank": 4} # run of 3
	]
	var defender_undercut = [
		{"suit": "Hearts", "rank": 9}, {"suit": "Spades", "rank": 9}, {"suit": "Diamonds", "rank": 9},
		{"suit": "Hearts", "rank": 10}, {"suit": "Spades", "rank": 10}, {"suit": "Diamonds", "rank": 10},
		{"suit": "Hearts", "rank": 11}, {"suit": "Hearts", "rank": 12}, {"suit": "Hearts", "rank": 13}, # run of 3
		{"suit": "Diamonds", "rank": 3} # deadwood 3 pts
	]
	var res2 = GinRummyEvaluator.evaluate_showdown(knocker_undercut, defender_undercut)
	assert(res2["winner"] == "defender", "Defender must win undercut")
	assert(res2["is_undercut"] == true, "Must be flagged as undercut")
	assert(res2["points_awarded"] == 25 + (5 - 3), "Undercut gives 25 + (5 - 3) = 27 pts, got %d" % res2["points_awarded"])

func test_gin_rummy_scene() -> void:
	print("[TEST] Testing Gin Rummy Scene instantiation and interactions...")
	var scene: PackedScene = load("res://scenes/gin_rummy.tscn")
	assert(scene != null, "Failed to load gin_rummy.tscn")
	var inst: GinRummyGame = scene.instantiate()
	inst.is_instant_mode = true
	root.add_child(inst)
	await process_frame

	assert(inst.player_cards.size() == 10, "Player must start with 10 cards, got %d" % inst.player_cards.size())
	assert(inst.ai_cards.size() == 10, "AI must start with 10 cards, got %d" % inst.ai_cards.size())
	assert(inst.discard_pile.size() == 1, "Discard pile should start with 1 card")
	assert(inst.stock_pile.size() == 31, "Stock pile should have 31 cards, got %d" % inst.stock_pile.size())

	# Test player drawing from stock
	inst.is_player_turn = true
	inst.current_phase = GinRummyGame.TurnPhase.DRAW
	inst._on_player_draw_stock()
	assert(inst.player_cards.size() == 11, "Player should have 11 cards after draw")
	assert(inst.current_phase == GinRummyGame.TurnPhase.DISCARD, "Phase should be DISCARD after draw")

	# Test selecting and discarding card
	var card_to_discard: GinRummyCard = inst.player_cards[0]
	inst._on_player_card_clicked(card_to_discard)
	assert(inst.selected_card == card_to_discard, "Card should be selected")
	inst._on_player_discard_selected()
	assert(inst.player_cards.size() == 10, "Player should have 10 cards after discard")
	assert(inst.discard_pile.size() == 2, "Discard pile should have 2 cards")

	# Test AI turn execution
	inst.is_player_turn = false
	inst.current_phase = GinRummyGame.TurnPhase.DRAW
	inst._execute_ai_turn()
	assert(inst.ai_cards.size() == 10, "AI should have 10 cards after AI turn completes")

	# Test showdown display
	inst._finalize_hand_with_knock(true, false)
	assert(inst.showdown_modal.visible == true, "Showdown modal must be visible after knock")

	inst.queue_free()
	await process_frame
	print("[PASS] Gin Rummy scene tests passed successfully!")
