extends SceneTree

const PyramidGame = preload("res://scripts/PyramidGame.gd")
const PyramidCard = preload("res://scripts/PyramidCard.gd")

func _initialize() -> void:
	print("--- BEGINNING PYRAMID SOLITAIRE TESTS ---")
	await test_pyramid_game_complete()
	print("--- ALL PYRAMID TESTS COMPLETED SUCCESSFULLY ---")
	quit(0)

func test_pyramid_game_complete() -> void:
	var scene: PackedScene = load("res://scenes/pyramid_solitaire.tscn")
	assert(scene != null, "Failed to load pyramid_solitaire.tscn")
	var game: PyramidGame = scene.instantiate()
	game.is_instant_mode = true
	root.add_child(game)
	await process_frame

	# 1. Verify UI and Scene Nodes
	assert(game.card_layer != null, "card_layer missing")
	assert(game.stock_slot != null, "stock_slot missing")
	assert(game.waste_slot != null, "waste_slot missing")
	assert(game.discard_slot != null, "discard_slot missing")
	assert(game.score_label != null, "score_label missing")
	assert(game.moves_label != null, "moves_label missing")
	assert(game.passes_label != null, "passes_label missing")
	assert(game.btn_undo != null, "btn_undo missing")
	assert(game.btn_hint != null, "btn_hint missing")
	assert(game.btn_restart != null, "btn_restart missing")
	assert(game.btn_menu != null, "btn_menu missing")
	assert(game.victory_dialog != null, "victory_dialog missing")

	# 2. Verify Deck and Initial Layout
	assert(game.all_cards.size() == 52, "Expected 52 total cards generated")
	assert(game.stock.size() == 24, "Expected 24 cards in stock")
	assert(game.waste.size() == 0, "Waste starts empty")
	assert(game.discard.size() == 0, "Discard starts empty")

	var total_pyramid_cards: int = 0
	for r in range(7):
		assert(game.pyramid_rows[r].size() == r + 1, "Row %d should have %d cards" % [r, r + 1])
		for c in range(r + 1):
			var card: PyramidCard = game.pyramid_rows[r][c]
			assert(card != null, "Pyramid card at row %d col %d should not be null" % [r, c])
			assert(card.is_face_up == true, "Pyramid card must be face-up")
			assert(card.pile_type == "pyramid", "Card pile must be pyramid")
			total_pyramid_cards += 1

			# Bottom row cards (row 6) must be exposed; rows 0..5 must be covered
			if r == 6:
				assert(card.is_exposed == true, "Bottom row card (%d, %d) must be exposed" % [r, c])
			else:
				assert(card.is_exposed == false, "Card at (%d, %d) must be covered initially" % [r, c])

	assert(total_pyramid_cards == 28, "Pyramid should contain exactly 28 cards")

	# 3. Test Exposed Logic (Covering children removal)
	# Card at (5, 0) is covered by (6, 0) and (6, 1)
	assert(game.pyramid_rows[5][0].is_exposed == false, "(5, 0) starts covered")
	var card_6_0: PyramidCard = game.pyramid_rows[6][0]
	var card_6_1: PyramidCard = game.pyramid_rows[6][1]

	# Remove only (6, 0)
	game.pyramid_rows[6][0] = null
	game.update_exposed_cards()
	assert(game.pyramid_rows[5][0].is_exposed == false, "(5, 0) still covered because (6, 1) exists")

	# Remove (6, 1) as well
	game.pyramid_rows[6][1] = null
	game.update_exposed_cards()
	assert(game.pyramid_rows[5][0].is_exposed == true, "(5, 0) should now be exposed after both children removed")

	# Restore cards for further testing
	game.pyramid_rows[6][0] = card_6_0
	game.pyramid_rows[6][1] = card_6_1
	game.update_exposed_cards()
	assert(game.pyramid_rows[5][0].is_exposed == false, "(5, 0) covered again after restoring children")

	# 4. Test Stock Draw and Waste Top Playability
	assert(game.stock.size() == 24, "Stock has 24 cards")
	assert(game.waste.size() == 0, "Waste has 0 cards")
	game._on_stock_clicked()
	assert(game.stock.size() == 23, "Stock has 23 cards after draw")
	assert(game.waste.size() == 1, "Waste has 1 card after draw")
	var top_waste: PyramidCard = game.waste.back()
	assert(top_waste.is_face_up == true, "Drawn card must be face up")
	assert(top_waste.is_exposed == true, "Top of waste must be exposed")

	# Draw another card
	game._on_stock_clicked()
	assert(game.stock.size() == 22, "Stock has 22 cards after 2nd draw")
	assert(game.waste.size() == 2, "Waste has 2 cards after 2nd draw")
	assert(game.waste[0].is_exposed == false, "Covered waste card must not be exposed")
	assert(game.waste[1].is_exposed == true, "Top waste card must be exposed")

	# 5. Test Undo for Stock Draw
	game._on_undo_clicked()
	assert(game.stock.size() == 23, "Stock restored to 23 after undo")
	assert(game.waste.size() == 1, "Waste restored to 1 after undo")
	game._on_undo_clicked()
	assert(game.stock.size() == 24, "Stock restored to 24 after 2nd undo")
	assert(game.waste.size() == 0, "Waste empty after 2nd undo")

	# 6. Test King Single Discard
	var test_king: PyramidCard = game.PyramidCardScene.instantiate()
	test_king.setup("Spades", 13, true)
	test_king.set_exposed(true)
	test_king.pile_type = "pyramid"
	test_king.row = 6
	test_king.col = 2
	game.pyramid_rows[6][2] = test_king
	game.card_layer.add_child(test_king)

	var prev_score: int = game.score
	var prev_moves: int = game.moves_count
	game._on_card_clicked(test_king)
	assert(game.pyramid_rows[6][2] == null, "King should be removed from pyramid")
	assert(game.discard.has(test_king), "King should be in discard pile")
	assert(game.score == prev_score + 10, "Score should increase by 10 for King")
	assert(game.moves_count == prev_moves + 1, "Moves count should increment")

	# Test Undo King Discard
	game._on_undo_clicked()
	assert(game.pyramid_rows[6][2] == test_king, "King restored to pyramid after undo")
	assert(not game.discard.has(test_king), "King removed from discard after undo")
	assert(game.score == prev_score, "Score restored after undo")
	assert(game.moves_count == prev_moves, "Moves restored after undo")

	# 7. Test Pairing (Sum to 13)
	var card_8: PyramidCard = game.PyramidCardScene.instantiate()
	card_8.setup("Hearts", 8, true)
	card_8.set_exposed(true)
	card_8.pile_type = "pyramid"
	card_8.row = 6
	card_8.col = 3
	game.pyramid_rows[6][3] = card_8
	game.card_layer.add_child(card_8)

	var card_5: PyramidCard = game.PyramidCardScene.instantiate()
	card_5.setup("Diamonds", 5, true)
	card_5.set_exposed(true)
	card_5.pile_type = "pyramid"
	card_5.row = 6
	card_5.col = 4
	game.pyramid_rows[6][4] = card_5
	game.card_layer.add_child(card_5)

	# Click card_8 (selects it)
	game._on_card_clicked(card_8)
	assert(game.selected_card == card_8, "card_8 should be selected")
	assert(card_8.is_card_selected == true, "card_8 selection glow active")

	# Click card_5 (sums to 13 -> match!)
	game._on_card_clicked(card_5)
	assert(game.selected_card == null, "Selection cleared after match")
	assert(game.pyramid_rows[6][3] == null, "card_8 removed from pyramid")
	assert(game.pyramid_rows[6][4] == null, "card_5 removed from pyramid")
	assert(game.discard.has(card_8), "card_8 in discard")
	assert(game.discard.has(card_5), "card_5 in discard")

	# Test Undo Pair Match
	game._on_undo_clicked()
	assert(game.pyramid_rows[6][3] == card_8, "card_8 restored after undo")
	assert(game.pyramid_rows[6][4] == card_5, "card_5 restored after undo")
	assert(not game.discard.has(card_8), "card_8 removed from discard")
	assert(not game.discard.has(card_5), "card_5 removed from discard")

	# 8. Test Non-matching Pair Click (Selection switches)
	var card_4: PyramidCard = game.PyramidCardScene.instantiate()
	card_4.setup("Clubs", 4, true)
	card_4.set_exposed(true)
	card_4.pile_type = "pyramid"
	card_4.row = 6
	card_4.col = 5
	game.pyramid_rows[6][5] = card_4
	game.card_layer.add_child(card_4)

	# Click card_8 (rank 8), then card_4 (rank 4) -> 8 + 4 = 12 != 13
	game._on_card_clicked(card_8)
	assert(game.selected_card == card_8, "card_8 selected")
	game._on_card_clicked(card_4)
	assert(game.selected_card == card_4, "Selection should switch to card_4 on invalid pair")
	assert(card_8.is_card_selected == false, "card_8 deselected")
	assert(card_4.is_card_selected == true, "card_4 selected")

	# Click card_4 again -> deselects
	game._on_card_clicked(card_4)
	assert(game.selected_card == null, "Clicking selected card deselects it")

	# 9. Test Hint Generation
	# Currently on board: card_8 and card_5 sum to 13!
	game._on_hint_clicked()
	assert(game.toast_panel.visible == true, "Toast should display hint message")
	assert("Hint" in game.toast_label.text, "Toast should mention Hint")

	# 10. Test Full Victory Condition
	# Simulate clearing the entire pyramid
	for r in range(7):
		for c in range(r + 1):
			game.pyramid_rows[r][c] = null

	assert(not game.is_game_over, "Game not over yet before check")
	game._check_victory()
	assert(game.is_game_over == true, "Game must be game over upon clearing pyramid")
	assert(game.victory_dialog.visible == true, "Victory dialog must be visible")
	assert(GameSettings.pyramid_wins >= 1, "Pyramid wins stat must be recorded")

	# Clean up test nodes
	test_king.queue_free()
	card_8.queue_free()
	card_5.queue_free()
	card_4.queue_free()
	game.queue_free()
	await process_frame
