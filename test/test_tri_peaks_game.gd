extends SceneTree

const TriPeaksGame = preload("res://scripts/TriPeaksGame.gd")
const TriPeaksCard = preload("res://scripts/TriPeaksCard.gd")

func _initialize() -> void:
	print("--- BEGINNING TRI PEAKS SOLITAIRE TESTS ---")
	await test_tri_peaks_game_complete()
	print("--- ALL TRI PEAKS TESTS COMPLETED SUCCESSFULLY ---")
	quit(0)

func test_tri_peaks_game_complete() -> void:
	var scene: PackedScene = load("res://scenes/tri_peaks_solitaire.tscn")
	assert(scene != null, "Failed to load tri_peaks_solitaire.tscn")
	var game: TriPeaksGame = scene.instantiate()
	game.is_instant_mode = true
	root.add_child(game)
	await process_frame

	# 1. Verify UI and Scene Nodes
	assert(game.card_layer != null, "card_layer missing")
	assert(game.stock_slot != null, "stock_slot missing")
	assert(game.waste_slot != null, "waste_slot missing")
	assert(game.score_label != null, "score_label missing")
	assert(game.streak_label != null, "streak_label missing")
	assert(game.moves_label != null, "moves_label missing")
	assert(game.time_label != null, "time_label missing")
	assert(game.passes_label != null, "passes_label missing")
	assert(game.btn_undo != null, "btn_undo missing")
	assert(game.btn_hint != null, "btn_hint missing")
	assert(game.btn_restart != null, "btn_restart missing")
	assert(game.btn_menu != null, "btn_menu missing")
	assert(game.victory_dialog != null, "victory_dialog missing")

	# 2. Verify Deck and Initial Layout
	assert(game.all_cards.size() == 52, "Expected 52 total cards generated, got %d" % game.all_cards.size())
	assert(game.stock.size() == 23, "Expected 23 cards in stock, got %d" % game.stock.size())
	assert(game.waste.size() == 1, "Expected 1 initial waste card, got %d" % game.waste.size())
	assert(game.waste.back().is_face_up == true, "Initial waste card must be face-up")

	var row_expected: Array[int] = [3, 6, 9, 10]
	var total_tableau_cards: int = 0
	for r in range(4):
		assert(game.tableau_rows[r].size() == row_expected[r], "Row %d expected %d cards, got %d" % [r, row_expected[r], game.tableau_rows[r].size()])
		for c in range(row_expected[r]):
			var card: TriPeaksCard = game.tableau_rows[r][c]
			assert(card != null, "Card at row %d col %d should not be null" % [r, c])
			assert(card.pile_type == "tableau", "Card pile must be tableau")
			total_tableau_cards += 1

			# Row 3 must be face up and exposed; rows 0..2 must be face down and covered
			if r == 3:
				assert(card.is_face_up == true, "Row 3 card must be face up")
				assert(card.is_exposed == true, "Row 3 card must be exposed")
			else:
				assert(card.is_face_up == false, "Row %d card must be face down" % r)
				assert(card.is_exposed == false, "Row %d card must be covered" % r)

	assert(total_tableau_cards == 28, "Tableau should contain exactly 28 cards")

	# 3. Test Covering / Uncovering Hierarchy
	# Card (2, 0) is covered by (3, 0) and (3, 1)
	assert(game.tableau_rows[2][0].is_exposed == false, "Card (2,0) starts covered")
	var card_3_0: TriPeaksCard = game.tableau_rows[3][0]
	var card_3_1: TriPeaksCard = game.tableau_rows[3][1]

	# Remove only (3, 0) -> (2, 0) must stay covered
	game.tableau_rows[3][0] = null
	game.update_exposed_cards()
	assert(game.tableau_rows[2][0].is_exposed == false, "(2,0) remains covered because (3,1) still exists")

	# Remove (3, 1) as well -> (2, 0) must uncover and flip face up!
	game.tableau_rows[3][1] = null
	game.update_exposed_cards()
	assert(game.tableau_rows[2][0].is_exposed == true, "(2,0) must become exposed after both children removed")
	assert(game.tableau_rows[2][0].is_face_up == true, "(2,0) must flip face up when uncovered")

	# Restore cards
	game.tableau_rows[3][0] = card_3_0
	game.tableau_rows[3][1] = card_3_1
	game.tableau_rows[2][0].set_exposed(false)
	game.tableau_rows[2][0].set_face_up(false)
	game.update_exposed_cards()

	# 4. Test Move Validation (±1 rank & Ace-King wrap)
	var waste_card: TriPeaksCard = game.TriPeaksCardScene.instantiate()
	waste_card.setup("Spades", 7, true)
	waste_card.set_exposed(true)
	waste_card.pile_type = "waste"
	game.waste.clear()
	game.waste.append(waste_card)
	game.card_layer.add_child(waste_card)

	var card_rank_8: TriPeaksCard = game.TriPeaksCardScene.instantiate()
	card_rank_8.setup("Hearts", 8, true)
	card_rank_8.set_exposed(true)
	card_rank_8.pile_type = "tableau"
	game.card_layer.add_child(card_rank_8)

	var card_rank_6: TriPeaksCard = game.TriPeaksCardScene.instantiate()
	card_rank_6.setup("Diamonds", 6, true)
	card_rank_6.set_exposed(true)
	card_rank_6.pile_type = "tableau"
	game.card_layer.add_child(card_rank_6)

	var card_rank_9: TriPeaksCard = game.TriPeaksCardScene.instantiate()
	card_rank_9.setup("Clubs", 9, true)
	card_rank_9.set_exposed(true)
	card_rank_9.pile_type = "tableau"
	game.card_layer.add_child(card_rank_9)

	var card_rank_7: TriPeaksCard = game.TriPeaksCardScene.instantiate()
	card_rank_7.setup("Clubs", 7, true)
	card_rank_7.set_exposed(true)
	card_rank_7.pile_type = "tableau"
	game.card_layer.add_child(card_rank_7)

	assert(game.can_play_to_waste(card_rank_8) == true, "8 can play on 7 (+1)")
	assert(game.can_play_to_waste(card_rank_6) == true, "6 can play on 7 (-1)")
	assert(game.can_play_to_waste(card_rank_9) == false, "9 cannot play on 7 (+2)")
	assert(game.can_play_to_waste(card_rank_7) == false, "7 cannot play on 7 (equal rank)")

	# Test Wrap Around (King <-> Ace)
	var waste_king: TriPeaksCard = game.TriPeaksCardScene.instantiate()
	waste_king.setup("Hearts", 13, true)
	waste_king.set_exposed(true)
	waste_king.pile_type = "waste"
	game.waste.clear()
	game.waste.append(waste_king)
	game.card_layer.add_child(waste_king)

	var card_ace: TriPeaksCard = game.TriPeaksCardScene.instantiate()
	card_ace.setup("Spades", 1, true)
	card_ace.set_exposed(true)
	card_ace.pile_type = "tableau"
	game.card_layer.add_child(card_ace)

	var card_queen: TriPeaksCard = game.TriPeaksCardScene.instantiate()
	card_queen.setup("Diamonds", 12, true)
	card_queen.set_exposed(true)
	card_queen.pile_type = "tableau"
	game.card_layer.add_child(card_queen)

	assert(game.can_play_to_waste(card_ace) == true, "Ace can play on King with wrap-around enabled")
	assert(game.can_play_to_waste(card_queen) == true, "Queen can play on King")

	# Test Ace as waste card
	game.waste.clear()
	game.waste.append(card_ace)
	var card_2: TriPeaksCard = game.TriPeaksCardScene.instantiate()
	card_2.setup("Hearts", 2, true)
	card_2.set_exposed(true)
	card_2.pile_type = "tableau"
	game.card_layer.add_child(card_2)

	assert(game.can_play_to_waste(waste_king) == true, "King can play on Ace with wrap-around")
	assert(game.can_play_to_waste(card_2) == true, "2 can play on Ace")

	# 5. Test Playing Card, Streak Building, and Undo
	game.current_streak = 0
	game.score = 0
	var prev_score: int = game.score
	var prev_moves: int = game.moves_count

	card_2.row = 3
	card_2.col = 2
	game.tableau_rows[3][2] = card_2
	game._play_card_to_waste(card_2)

	assert(game.tableau_rows[3][2] == null, "card_2 removed from tableau")
	assert(game.waste.back() == card_2, "card_2 is now on top of waste")
	assert(game.current_streak == 1, "Streak should be 1 after 1st card")
	assert(game.score == prev_score + 10, "Score should be +10 for streak 1")
	assert(game.moves_count == prev_moves + 1, "Moves count incremented")

	# Play next card (rank 3 on rank 2) to test streak 2
	var card_3: TriPeaksCard = game.TriPeaksCardScene.instantiate()
	card_3.setup("Clubs", 3, true)
	card_3.set_exposed(true)
	card_3.pile_type = "tableau"
	card_3.row = 3
	card_3.col = 3
	game.tableau_rows[3][3] = card_3
	game.card_layer.add_child(card_3)

	game._play_card_to_waste(card_3)
	assert(game.current_streak == 2, "Streak should be 2 after 2nd card")
	assert(game.score == prev_score + 10 + 20, "Score should increase by 20 (10 * 2)")

	# Undo the 2nd move
	game._on_undo_clicked()
	assert(game.tableau_rows[3][3] == card_3, "card_3 restored after undo")
	assert(game.current_streak == 1, "Streak reverted to 1")
	assert(game.score == prev_score + 10, "Score reverted after undo")

	# 6. Test Peak Cleared Bonus
	var peak_card: TriPeaksCard = game.TriPeaksCardScene.instantiate()
	peak_card.setup("Diamonds", 3, true)
	peak_card.set_exposed(true)
	peak_card.pile_type = "tableau"
	peak_card.row = 0
	peak_card.col = 0
	peak_card.peak_idx = 0
	game.tableau_rows[0][0] = peak_card
	game.card_layer.add_child(peak_card)

	var score_before_peak: int = game.score
	# Waste top is card_2 (rank 2), peak_card is rank 3 (+1 match)
	game._play_card_to_waste(peak_card)
	# 1st peak bonus is +150, plus streak 2 points (+20) = +170
	assert(game.peaks_cleared == 1, "peaks_cleared should be 1")
	assert(game.score == score_before_peak + 20 + 150, "Peak 1 bonus should award +150 plus streak")

	# Undo peak cleared
	game._on_undo_clicked()
	assert(game.tableau_rows[0][0] == peak_card, "Peak card restored")
	assert(game.peaks_cleared == 0, "peaks_cleared reverted to 0")
	assert(game.score == score_before_peak, "Score reverted after peak undo")

	# 7. Test Stock Draw and Streak Reset
	game.current_streak = 5
	var stock_count_before: int = game.stock.size()
	game._on_stock_clicked()
	assert(game.stock.size() == stock_count_before - 1, "Stock size should decrease by 1")
	assert(game.current_streak == 0, "Drawing from stock must reset streak to 0")

	# Undo stock draw
	game._on_undo_clicked()
	assert(game.stock.size() == stock_count_before, "Stock restored after undo")
	assert(game.current_streak == 5, "Streak restored after undo")

	# 8. Test Stock Recycle
	game.stock.clear()
	game.stock_passes_used = 0
	game.max_stock_passes = 3
	# Ensure waste has multiple cards
	for i in range(4):
		var extra: TriPeaksCard = game.TriPeaksCardScene.instantiate()
		extra.setup("Hearts", 4 + i, true)
		extra.pile_type = "waste"
		game.waste.append(extra)
		game.card_layer.add_child(extra)

	var waste_count_before: int = game.waste.size()
	game._on_stock_clicked() # Should recycle waste (except top card)
	assert(game.stock_passes_used == 1, "Passes used should be 1 after recycle")
	assert(game.waste.size() == 1, "Only top waste card remains on waste after recycle")
	assert(game.stock.size() == waste_count_before - 1, "Recycled cards returned to stock")

	# 9. Test Hint Feature
	game._on_hint_clicked()
	assert(game.toast_panel.visible == true, "Hint toast should be displayed")

	# 10. Test Victory Condition
	for r in range(4):
		for c in range(game.tableau_rows[r].size()):
			game.tableau_rows[r][c] = null
	game._check_victory()
	assert(game.is_game_over == true, "Game is over upon victory")
	assert(game.victory_dialog.visible == true, "Victory dialog visible")

	# Clean up test nodes
	waste_card.queue_free()
	card_rank_8.queue_free()
	card_rank_6.queue_free()
	card_rank_9.queue_free()
	card_rank_7.queue_free()
	waste_king.queue_free()
	card_ace.queue_free()
	card_queen.queue_free()
	card_2.queue_free()
	card_3.queue_free()
	peak_card.queue_free()
	game.queue_free()
	await process_frame
	print("[PASS] Tri Peaks Solitaire tests passed!")
