extends SceneTree

func _initialize():
	print("--- BEGIN TEST SOLITAIRE VISUALS & HOVER GLOW ---")
	var sol_scene: PackedScene = load("res://scenes/solitaire.tscn")
	assert(sol_scene != null, "solitaire.tscn should load")
	var sol: SolitaireGame = sol_scene.instantiate()
	root.add_child(sol)
	await process_frame
	sol.deal_instantly()
	await process_frame

	# 1. Test green table background
	print("[TEST 1] Verifying green table just like domino...")
	var table_bg = sol.get_node_or_null("TableBackground") as Panel
	assert(table_bg != null, "TableBackground node should exist")
	var table_style = table_bg.get_theme_stylebox("panel") as StyleBoxFlat
	assert(table_style != null, "TableBackground should have StyleBoxFlat")
	assert(is_equal_approx(table_style.bg_color.r, 0.08) and is_equal_approx(table_style.bg_color.g, 0.24) and is_equal_approx(table_style.bg_color.b, 0.16),
		"Table background should match domino green felt color")
	assert(table_style.border_width_left == 12 and table_style.border_width_top == 12, "Table should have 12px wood rim border")
	assert(table_style.corner_radius_top_left == 24, "Table should have 24px corner radius")
	assert(table_style.shadow_size >= 10, "Table should have drop shadow")
	print("[PASS] Test 1: Green table with wood border and shadow verified!")

	# 2. Test visible borders for every slot
	print("[TEST 2] Verifying visible border for every slot...")
	var all_slots: Array[Panel] = [sol.stock_slot, sol.waste_slot]
	all_slots.append_array(sol.foundation_slots)
	all_slots.append_array(sol.tableau_slots)
	assert(all_slots.size() == 13, "Expected 13 slots total")

	for s in all_slots:
		var slot_style = s.get_theme_stylebox("panel") as StyleBoxFlat
		assert(slot_style != null, "Slot %s must have StyleBoxFlat" % s.name)
		assert(slot_style.border_width_left >= 2 and slot_style.border_width_top >= 2, "Slot %s border width must be at least 2px" % s.name)
		assert(slot_style.border_color.a >= 0.4, "Slot %s border color must have visible alpha >= 0.4" % s.name)
		var glow = s.get_node_or_null("HighlightGlow") as Panel
		assert(glow != null, "Slot %s must have a HighlightGlow child" % s.name)
		assert(not glow.visible, "Slot %s HighlightGlow should be hidden initially" % s.name)
	print("[PASS] Test 2: Visible borders and HighlightGlow verified on all 13 slots!")

	# 3. Test card hover glow
	print("[TEST 3] Verifying card hover glowing border...")
	var test_card: SolitaireCard = sol.all_cards[0]
	assert(not test_card.highlight_glow.visible, "Card glow should start false")

	test_card._on_mouse_entered()
	assert(test_card.highlight_glow.visible, "Card glow should be visible on mouse enter")

	test_card._on_mouse_exited()
	assert(not test_card.highlight_glow.visible, "Card glow should turn off on mouse exit")
	print("[PASS] Test 3: Card hover glowing border works perfectly!")

	# 4. Test slot hover glow (when slot is hovered directly)
	print("[TEST 4] Verifying empty slot hover glowing border...")
	var f0 = sol.foundation_slots[0]
	var f0_glow = f0.get_node("HighlightGlow") as Panel
	assert(not f0_glow.visible, "Foundation0 glow should start false")

	sol._on_slot_mouse_entered(f0)
	assert(f0_glow.visible, "Foundation0 glow should be visible on mouse enter")

	sol._on_slot_mouse_exited(f0)
	assert(not f0_glow.visible, "Foundation0 glow should turn off on mouse exit")
	print("[PASS] Test 4: Slot hover glowing border works perfectly!")

	# 5. Test drag slot hover glowing border
	print("[TEST 5] Verifying drag slot hover glowing border...")
	var top_waste_or_tableau: SolitaireCard = null
	for col in range(7):
		if not sol.tableau[col].is_empty() and sol.tableau[col].back().is_face_up:
			top_waste_or_tableau = sol.tableau[col].back()
			break
	assert(top_waste_or_tableau != null, "Found face-up card for drag test")

	# Start drag
	sol._on_card_drag_started(top_waste_or_tableau, top_waste_or_tableau.global_position)
	assert(top_waste_or_tableau.highlight_glow.visible, "Dragged card should have glowing border while dragging")

	# Drag over foundation 0
	var f0_pos = sol.FOUNDATION_POSITIONS[0] + Vector2(50, 68)
	sol._on_card_drag_updated(top_waste_or_tableau, f0_pos)
	assert(f0_glow.visible, "Foundation0 slot should glow when card is dragged over it")

	# Move drag to empty space
	sol._on_card_drag_updated(top_waste_or_tableau, Vector2(50, 500))
	assert(not f0_glow.visible, "Foundation0 slot should un-glow when dragged card moves away")

	# End drag
	sol._on_card_drag_ended(top_waste_or_tableau, Vector2(50, 500))
	assert(not top_waste_or_tableau.highlight_glow.visible, "Dragged card glow should turn off when drag ends")
	assert(not f0_glow.visible, "Foundation0 slot glow should be off when drag ends")
	print("[PASS] Test 5: Drag slot hover and dragged card glowing border verified!")

	sol.queue_free()
	await process_frame
	print("--- ALL SOLITAIRE VISUAL & GLOW TESTS PASSED ---")
	quit(0)
