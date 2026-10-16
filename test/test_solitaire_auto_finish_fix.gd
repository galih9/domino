extends SceneTree

const SolitaireGame = preload("res://scripts/SolitaireGame.gd")
const SolitaireCard = preload("res://scripts/SolitaireCard.gd")

func _initialize() -> void:
	print("--- TEST SOLITAIRE AUTO FINISH REPRODUCTION ---")
	await test_auto_finish_stuck()
	print("--- TEST PASSED ---")
	quit(0)

func test_auto_finish_stuck() -> void:
	var sol_scene: PackedScene = load("res://scenes/solitaire.tscn")
	var game: SolitaireGame = sol_scene.instantiate()
	root.add_child(game)
	await process_frame
	game.deal_instantly()
	await process_frame

	# Clear all piles
	for col in game.tableau:
		col.clear()
	game.stock.clear()
	game.waste.clear()
	for f in game.foundations:
		f.clear()

	# Map cards by suit and rank
	var cards_map: Dictionary = {}
	for c in game.all_cards:
		cards_map["%s_%d" % [c.suit, c.rank]] = c

	# Foundations:
	# F0: Clubs 1..12
	for r in range(1, 13):
		var c: SolitaireCard = cards_map["Clubs_%d" % r]
		c.pile_type = "foundation"
		c.pile_index = 0
		c.set_face_up(true)
		game.foundations[0].append(c)

	# F1: Hearts 1..11
	for r in range(1, 12):
		var c: SolitaireCard = cards_map["Hearts_%d" % r]
		c.pile_type = "foundation"
		c.pile_index = 1
		c.set_face_up(true)
		game.foundations[1].append(c)

	# F2: Spades 1..12
	for r in range(1, 13):
		var c: SolitaireCard = cards_map["Spades_%d" % r]
		c.pile_type = "foundation"
		c.pile_index = 2
		c.set_face_up(true)
		game.foundations[2].append(c)

	# F3: Diamonds 1..13
	for r in range(1, 14):
		var c: SolitaireCard = cards_map["Diamonds_%d" % r]
		c.pile_type = "foundation"
		c.pile_index = 3
		c.set_face_up(true)
		game.foundations[3].append(c)

	# Waste: King of Hearts
	var k_hearts: SolitaireCard = cards_map["Hearts_13"]
	k_hearts.pile_type = "waste"
	k_hearts.pile_index = 0
	k_hearts.set_face_up(true)
	game.waste.append(k_hearts)

	# Stock: Queen of Hearts, King of Clubs, King of Spades
	for key in ["Hearts_12", "Clubs_13", "Spades_13"]:
		var c: SolitaireCard = cards_map[key]
		c.pile_type = "stock"
		c.pile_index = 0
		c.set_face_up(false)
		game.stock.append(c)

	game._layout_all_piles_instant()
	game._restack_cards()
	game._check_auto_finish_available()

	print("Stock size: %d, Waste size: %d, Foundations total: %d" % [
		game.stock.size(), game.waste.size(),
		game.foundations[0].size() + game.foundations[1].size() + game.foundations[2].size() + game.foundations[3].size()
	])
	assert(game.btn_auto_finish.visible, "Auto finish should be visible")

	print("Triggering auto finish...")
	var start_time := Time.get_ticks_msec()
	await game._on_auto_finish_clicked()
	var elapsed := (Time.get_ticks_msec() - start_time) / 1000.0
	print("Auto finish finished in %.2f seconds." % elapsed)

	assert(game._is_all_on_foundations(), "All cards should be on foundations")
	assert(game.is_game_over, "Game should be marked won")
	assert(not game._is_any_card_moving(), "No cards should be moving")
	assert(not game.is_auto_finishing, "is_auto_finishing should be false")
	assert(elapsed < 2.5, "Auto finish should complete promptly without 15-second hang")

	# Test 2: Deadlock scenario where no cards can move to foundations or tableau
	print("\n[TEST 2] Testing deadlock scenario where cards cannot move...")
	# Setup: foundations empty, stock has 2 Kings, waste has 2 Queens
	for col in game.tableau:
		col.clear()
	game.stock.clear()
	game.waste.clear()
	for f in game.foundations:
		f.clear()

	var k1: SolitaireCard = cards_map["Spades_13"]
	k1.pile_type = "stock"
	k1.set_face_up(false)
	game.stock.append(k1)

	var q1: SolitaireCard = cards_map["Spades_12"]
	q1.pile_type = "waste"
	q1.set_face_up(true)
	game.waste.append(q1)

	# Block tableau with cards that cannot accept Queen or King
	for col_idx in range(7):
		var ace: SolitaireCard = game.all_cards[col_idx]
		ace.pile_type = "tableau"
		ace.pile_index = col_idx
		ace.set_face_up(true)
		game.tableau[col_idx].append(ace)

	game._layout_all_piles_instant()
	game._restack_cards()

	var deadlock_start := Time.get_ticks_msec()
	await game._on_auto_finish_clicked()
	var deadlock_elapsed := (Time.get_ticks_msec() - deadlock_start) / 1000.0
	print("Deadlock auto finish exited in %.2f seconds." % deadlock_elapsed)

	assert(deadlock_elapsed < 1.0, "Deadlock must exit quickly after cycling without hang")
	assert(not game.is_auto_finishing, "is_auto_finishing should be false after deadlock")
	assert(not game._is_any_card_moving(), "No card should be moving after deadlock")
	print("[PASS] Deadlock handled gracefully without freezing!")
