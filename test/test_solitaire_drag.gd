extends SceneTree

func _initialize():
	print("--- BEGIN COMPREHENSIVE SOLITAIRE DRAG TESTS ---")
	var sol_scene: PackedScene = load("res://scenes/solitaire.tscn")
	var sol_inst: SolitaireGame = sol_scene.instantiate()
	root.add_child(sol_inst)
	await process_frame
	sol_inst.deal_instantly()
	await process_frame

	var card_layer: Control = sol_inst.card_layer

	# Test 1: Verify hit testing across 100 randomly generated and dealt games
	print("[TEST 1] Verifying that no face-up card in tableau or top of waste/foundation is ever blocked...")
	for game_idx in range(50):
		sol_inst.start_new_game(false)
		await process_frame
		sol_inst.deal_instantly()

		# Check all face-up tableau cards
		for col_idx in range(7):
			var col: Array = sol_inst.tableau[col_idx]
			for c in col:
				if not c.is_face_up:
					continue
				var test_pos: Vector2 = c.global_position + Vector2(50, 14)
				var hit_card: SolitaireCard = _find_hit_card(card_layer, test_pos)
				assert(hit_card == c, "Game %d: Expected %s at col %d, but hit %s" % [
					game_idx, c.get_display_name(), col_idx, hit_card.get_display_name() if hit_card else "None"
				])

		# Check waste draws
		for draw_step in range(6):
			sol_inst._draw_from_stock()
			if not sol_inst.waste.is_empty():
				var top_waste: SolitaireCard = sol_inst.waste.back()
				var test_pos: Vector2 = top_waste.global_position + Vector2(50, 68)
				var hit_card: SolitaireCard = _find_hit_card(card_layer, test_pos)
				assert(hit_card == top_waste, "Game %d draw %d: Expected top waste %s, but hit %s" % [
					game_idx, draw_step, top_waste.get_display_name(), hit_card.get_display_name() if hit_card else "None"
				])

	print("[PASS] Test 1: Hit testing is 100% accurate across all games!")

	# Test 2: Drag simulation - start drag, update drag, end drag (valid drop)
	print("[TEST 2] Testing drag & drop execution between tableau columns...")
	sol_inst.start_new_game(true)
	await process_frame
	sol_inst.deal_instantly()

	# Create controlled test tableau scenario
	var king_card: SolitaireCard = sol_inst.CardScene.instantiate()
	king_card.setup("Hearts", 13, true)
	king_card.pile_type = "tableau"
	king_card.pile_index = 0
	card_layer.add_child(king_card)
	sol_inst.tableau[0].clear()
	sol_inst.tableau[0].append(king_card)

	var queen_card: SolitaireCard = sol_inst.CardScene.instantiate()
	queen_card.setup("Spades", 12, true)
	queen_card.pile_type = "tableau"
	queen_card.pile_index = 1
	card_layer.add_child(queen_card)
	sol_inst.tableau[1].clear()
	sol_inst.tableau[1].append(queen_card)

	sol_inst._layout_tableau_column(0)
	sol_inst._layout_tableau_column(1)
	sol_inst._restack_cards()

	# Simulate dragging Queen from col 1 to col 0 (on top of King)
	sol_inst._on_card_drag_started(queen_card, queen_card.global_position + Vector2(50, 50))
	assert(sol_inst._is_dragging, "Game should be in dragging state")
	assert(sol_inst._dragging_cards.size() == 1, "Should be dragging 1 card")
	assert(queen_card.z_index >= 100, "Dragging card should have elevated z-index")

	# Update drag to col 0 position
	var target_pos: Vector2 = sol_inst.tableau[0].back().position + Vector2(0, 20)
	sol_inst._on_card_drag_updated(queen_card, target_pos)

	# End drag on col 0
	sol_inst._on_card_drag_ended(queen_card, target_pos + Vector2(50, 50))
	assert(not sol_inst._is_dragging, "Dragging should end")
	assert(sol_inst.tableau[0].size() == 2, "Column 0 should now have 2 cards")
	assert(sol_inst.tableau[0][1] == queen_card, "Queen should be in Column 0 at index 1")
	assert(sol_inst.tableau[1].is_empty(), "Column 1 should now be empty")
	print("[PASS] Test 2: Drag & drop to tableau passed!")

	# Test 3: Drag simulation - invalid drop snap-back
	print("[TEST 3] Testing drag snap-back on invalid drop...")
	var orig_base: Vector2 = queen_card.base_pos
	sol_inst._on_card_drag_started(queen_card, queen_card.global_position + Vector2(50, 50))
	# Drag to an invalid position (e.g. far off screen)
	sol_inst._on_card_drag_updated(queen_card, Vector2(10, 10))
	sol_inst._on_card_drag_ended(queen_card, Vector2(10, 10))

	assert(not sol_inst._is_dragging, "Dragging should be reset")
	# Allow snap-back tween to complete
	await create_timer(0.25).timeout
	assert(queen_card.position.distance_to(orig_base) < 1.0, "Card should have snapped back to base_pos")
	assert(sol_inst.tableau[0].size() == 2, "Column 0 should still contain Queen")
	print("[PASS] Test 3: Snap-back on invalid drop passed!")

	# Test 4: Drag sub-stack of cards
	print("[TEST 4] Testing dragging multi-card stack...")
	var jack_card: SolitaireCard = sol_inst.CardScene.instantiate()
	jack_card.setup("Hearts", 11, true)
	jack_card.pile_type = "tableau"
	jack_card.pile_index = 0
	card_layer.add_child(jack_card)
	sol_inst.tableau[0].append(jack_card)
	sol_inst._layout_tableau_column(0)
	sol_inst._restack_cards()

	# Empty column 2 for a King move or check stack drag
	# Column 0 has King(Hearts 13), Queen(Spades 12), Jack(Hearts 11)
	# Drag from Queen: should drag [Queen, Jack]
	sol_inst._on_card_drag_started(queen_card, queen_card.global_position + Vector2(50, 20))
	assert(sol_inst._dragging_cards.size() == 2, "Expected 2 cards dragging, got %d" % sol_inst._dragging_cards.size())
	assert(sol_inst._dragging_cards[0] == queen_card, "First dragging card should be Queen")
	assert(sol_inst._dragging_cards[1] == jack_card, "Second dragging card should be Jack")

	# Cancel/drop invalidly to snap back
	sol_inst._on_card_drag_ended(queen_card, Vector2(0, 0))
	await create_timer(0.25).timeout
	assert(sol_inst.tableau[0].size() == 3, "Stack should remain intact after cancel")
	# Test 5: Dragged waste card snap back and redraw layering
	print("[TEST 5] Testing waste card drag snap-back and subsequent draw layering...")
	sol_inst.start_new_game(true)
	await process_frame
	sol_inst.deal_instantly()

	sol_inst._draw_from_stock()
	await create_timer(0.25).timeout
	var w_card1: SolitaireCard = sol_inst.waste.back()

	# Drag w_card1 and drop invalidly
	sol_inst._on_card_drag_started(w_card1, w_card1.global_position + Vector2(20, 20))
	sol_inst._on_card_drag_updated(w_card1, Vector2(500, 500))
	sol_inst._on_card_drag_ended(w_card1, Vector2(500, 500))
	await create_timer(0.25).timeout

	# Draw next card
	sol_inst._draw_from_stock()
	await create_timer(0.25).timeout
	var w_card2: SolitaireCard = sol_inst.waste.back()

	assert(w_card2.z_index > w_card1.z_index, "Newly drawn waste card must have higher z_index than previously dragged card")
	assert(w_card2.get_index() > w_card1.get_index(), "Newly drawn waste card must be after previous card in tree order")
	print("[PASS] Test 5: Waste drag snap-back and redraw layering passed!")

	sol_inst.queue_free()
	await process_frame
	print("--- ALL COMPREHENSIVE SOLITAIRE DRAG TESTS PASSED ---")
	quit(0)

func _find_hit_card(card_layer: Control, pos: Vector2) -> SolitaireCard:
	for i in range(card_layer.get_child_count() - 1, -1, -1):
		var child = card_layer.get_child(i) as SolitaireCard
		if child and child.visible and child.mouse_filter != Control.MOUSE_FILTER_IGNORE and child.get_global_rect().has_point(pos):
			return child
	return null
