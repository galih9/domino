extends SceneTree

func _initialize() -> void:
	print("--- BEGINNING AUTOMATED TESTS ---")
	await test_main_menu()
	await test_solitaire_mode()
	await test_classic_mode()
	print("--- ALL TESTS COMPLETED SUCCESSFULLY ---")
	quit(0)

func test_main_menu() -> void:
	print("[TEST] Testing Main Menu Scene & Game Settings...")
	var menu_scene: PackedScene = load("res://scenes/main_menu.tscn")
	assert(menu_scene != null, "Failed to load main_menu.tscn")
	var menu_inst: MainMenu = menu_scene.instantiate()
	root.add_child(menu_inst)
	await process_frame

	# Verify views & modals exist
	assert(menu_inst.main_menu_view != null, "main_menu_view missing")
	assert(menu_inst.mode_select_view != null, "mode_select_view missing")
	assert(menu_inst.themes_modal != null, "themes_modal missing")
	assert(menu_inst.rules_modal != null, "rules_modal missing")

	# Test theme selection
	ThemeManager.set_theme("Dark")
	assert(ThemeManager.get_theme() == "Dark", "Theme should be Dark")
	ThemeManager.set_theme("Light")
	assert(ThemeManager.get_theme() == "Light", "Theme should be Light")

	# Test game settings updates
	GameSettings.classic_opponents = 2
	assert(GameSettings.classic_opponents == 2, "classic_opponents should be 2")
	GameSettings.set_solitaire_draw_count(3)
	assert(GameSettings.solitaire_draw_count == 3, "solitaire_draw_count should be 3")
	GameSettings.set_solitaire_draw_count(1)
	assert(GameSettings.solitaire_draw_count == 1, "solitaire_draw_count should be 1")

	# Test card back setting
	GameSettings.set_card_back("cardBack_red1.png")
	assert(GameSettings.solitaire_card_back == "cardBack_red1.png", "Card back should be red1")
	assert(CardTheme.current_back == "cardBack_red1.png", "CardTheme back should be updated")

	# Test Solitaire mode buttons in ModeSelectView
	assert(menu_inst.btn_solitaire_draw1 != null, "btn_solitaire_draw1 missing")
	assert(menu_inst.btn_solitaire_draw3 != null, "btn_solitaire_draw3 missing")
	assert(menu_inst.btn_card_back_blue != null, "btn_card_back_blue missing")
	assert(menu_inst.btn_card_back_red != null, "btn_card_back_red missing")
	assert(menu_inst.btn_card_back_green != null, "btn_card_back_green missing")
	assert(menu_inst.btn_start_solitaire != null, "btn_start_solitaire missing")

	# Simulate button clicks
	menu_inst.btn_solitaire_draw3.pressed.emit()
	assert(GameSettings.solitaire_draw_count == 3, "Draw 3 button should update settings")
	menu_inst.btn_card_back_green.pressed.emit()
	assert(GameSettings.solitaire_card_back.begins_with("cardBack_green"), "Green back button should update settings")

	# Rules modal tabs
	assert(menu_inst.btn_tab_classic != null, "btn_tab_classic missing")
	assert(menu_inst.btn_tab_solitaire != null, "btn_tab_solitaire missing")
	assert(menu_inst.rules_classic_content != null, "rules_classic_content missing")
	assert(menu_inst.rules_solitaire_content != null, "rules_solitaire_content missing")

	menu_inst.btn_tab_solitaire.pressed.emit()
	assert(menu_inst.rules_solitaire_content.visible, "Solitaire rules should be visible when tab clicked")
	assert(not menu_inst.rules_classic_content.visible, "Classic rules should be hidden")

	menu_inst.queue_free()
	await process_frame
	print("[PASS] Main Menu tests passed!")

func test_solitaire_mode() -> void:
	print("[TEST] Testing Klondike Solitaire Mode Scene & Logic...")
	var sol_scene: PackedScene = load("res://scenes/solitaire.tscn")
	assert(sol_scene != null, "Failed to load solitaire.tscn")
	var sol_inst: SolitaireGame = sol_scene.instantiate()
	root.add_child(sol_inst)
	await process_frame
	sol_inst.deal_instantly()
	await process_frame

	# 1. Deck & Pile setup verification
	assert(sol_inst.all_cards.size() == 52, "Expected 52 playing cards generated, got %d" % sol_inst.all_cards.size())
	assert(sol_inst.stock.size() == 24, "Expected 24 cards in stock, got %d" % sol_inst.stock.size())
	assert(sol_inst.waste.size() == 0, "Waste should start empty")
	assert(sol_inst.foundations.size() == 4, "Expected 4 foundation piles")
	for f in sol_inst.foundations:
		assert(f.size() == 0, "Foundations should start empty")

	assert(sol_inst.tableau.size() == 7, "Expected 7 tableau columns")
	var total_tableau_cards: int = 0
	for col_idx in range(7):
		var col: Array = sol_inst.tableau[col_idx]
		assert(col.size() == col_idx + 1, "Tableau col %d should have %d cards, got %d" % [col_idx, col_idx + 1, col.size()])
		total_tableau_cards += col.size()
		# Only top card should be face up
		for row_idx in range(col.size()):
			var c: SolitaireCard = col[row_idx]
			if row_idx == col.size() - 1:
				assert(c.is_face_up, "Top card of col %d should be face up" % col_idx)
			else:
				assert(not c.is_face_up, "Card at row %d in col %d should be face down" % [row_idx, col_idx])
	assert(total_tableau_cards == 28, "Total tableau cards should be 28")

	# 2. Card Assets & Textures Verification
	for suit in ["Clubs", "Diamonds", "Hearts", "Spades"]:
		for rank in [1, 7, 11, 12, 13]: # Ace, 7, Jack, Queen, King
			var tex: Texture2D = CardTheme.get_card_texture(suit, rank)
			assert(tex != null, "Texture for %s rank %d should exist" % [suit, rank])
	var back_tex: Texture2D = CardTheme.get_back_texture()
	assert(back_tex != null, "Card back texture should exist")

	# 3. Stock Draw 1 & Undo
	sol_inst.draw_count = 1
	var prev_moves: int = sol_inst.moves_count
	sol_inst._draw_from_stock()
	assert(sol_inst.stock.size() == 23, "Stock should have 23 cards after Draw 1")
	assert(sol_inst.waste.size() == 1, "Waste should have 1 card after Draw 1")
	assert(sol_inst.waste.back().is_face_up, "Drawn waste card should be face up")
	assert(sol_inst.moves_count == prev_moves + 1, "Moves count should increment on draw")
	assert(sol_inst.undo_stack.size() == 1, "Undo stack should have 1 entry")

	# Undo stock draw
	sol_inst._on_undo_clicked()
	assert(sol_inst.stock.size() == 24, "Stock should be restored to 24 after undo")
	assert(sol_inst.waste.size() == 0, "Waste should be empty after undo")
	assert(sol_inst.undo_stack.size() == 0, "Undo stack should be empty")

	# 4. Stock Draw 3 & Undo
	sol_inst.draw_count = 3
	sol_inst._draw_from_stock()
	assert(sol_inst.stock.size() == 21, "Stock should have 21 cards after Draw 3")
	assert(sol_inst.waste.size() == 3, "Waste should have 3 cards after Draw 3")
	for c in sol_inst.waste:
		assert(c.is_face_up, "All drawn cards should be face up")

	# Undo Draw 3
	sol_inst._on_undo_clicked()
	assert(sol_inst.stock.size() == 24, "Stock should be restored to 24 after Draw 3 undo")
	assert(sol_inst.waste.size() == 0, "Waste should be empty after Draw 3 undo")
	sol_inst.draw_count = 1

	# 5. Foundation Rule Validation
	var card_ace_spades: SolitaireCard = sol_inst.CardScene.instantiate()
	card_ace_spades.setup("Spades", 1, true)
	var card_2_spades: SolitaireCard = sol_inst.CardScene.instantiate()
	card_2_spades.setup("Spades", 2, true)
	var card_2_hearts: SolitaireCard = sol_inst.CardScene.instantiate()
	card_2_hearts.setup("Hearts", 2, true)
	var card_king_spades: SolitaireCard = sol_inst.CardScene.instantiate()
	card_king_spades.setup("Spades", 13, true)

	# Empty foundation only accepts Ace
	assert(sol_inst._can_card_go_to_foundation(card_ace_spades, 0), "Ace should be accepted on empty foundation")
	assert(not sol_inst._can_card_go_to_foundation(card_2_spades, 0), "2 should NOT be accepted on empty foundation")
	assert(not sol_inst._can_card_go_to_foundation(card_king_spades, 0), "King should NOT be accepted on empty foundation")

	# Put Ace in foundation 0 and test next card
	sol_inst.foundations[0].append(card_ace_spades)
	assert(sol_inst._can_card_go_to_foundation(card_2_spades, 0), "2 of Spades should be accepted on Ace of Spades")
	assert(not sol_inst._can_card_go_to_foundation(card_2_hearts, 0), "2 of Hearts should NOT be accepted on Ace of Spades (suit mismatch)")
	sol_inst.foundations[0].clear()

	# 6. Tableau Rule Validation
	var card_red_king: SolitaireCard = sol_inst.CardScene.instantiate()
	card_red_king.setup("Hearts", 13, true)
	var card_black_queen: SolitaireCard = sol_inst.CardScene.instantiate()
	card_black_queen.setup("Spades", 12, true)
	var card_red_queen: SolitaireCard = sol_inst.CardScene.instantiate()
	card_red_queen.setup("Diamonds", 12, true)
	var card_black_jack: SolitaireCard = sol_inst.CardScene.instantiate()
	card_black_jack.setup("Clubs", 11, true)

	# Test empty tableau column
	var empty_col: Array = []
	sol_inst.tableau.append(empty_col)
	var empty_idx: int = sol_inst.tableau.size() - 1
	assert(sol_inst._can_cards_go_to_tableau(card_red_king, empty_idx), "King can move to empty tableau slot")
	assert(not sol_inst._can_cards_go_to_tableau(card_black_queen, empty_idx), "Queen cannot move to empty tableau slot")
	sol_inst.tableau.pop_back()

	# Test descending alternating color stacking
	# Red King -> accepts Black Queen, rejects Red Queen, rejects Black Jack
	var test_col: Array = [card_red_king]
	sol_inst.tableau.append(test_col)
	var test_idx: int = sol_inst.tableau.size() - 1
	assert(sol_inst._can_cards_go_to_tableau(card_black_queen, test_idx), "Black Queen on Red King should be valid")
	assert(not sol_inst._can_cards_go_to_tableau(card_red_queen, test_idx), "Red Queen on Red King should be invalid (same color)")
	assert(not sol_inst._can_cards_go_to_tableau(card_black_jack, test_idx), "Black Jack on Red King should be invalid (rank jump)")
	sol_inst.tableau.pop_back()

	# 7. Auto-Finish Availability Check
	# Initially, hidden cards exist, so auto-finish is false
	sol_inst._check_auto_finish_available()
	assert(not sol_inst.btn_auto_finish.visible, "Auto finish button should not be visible when hidden cards exist")

	# 8. Hint Button & Toast
	sol_inst._on_hint_clicked()
	assert(sol_inst.toast_panel.visible, "Toast should be visible when Hint is clicked")

	# 9. Victory Trigger
	sol_inst._trigger_victory()
	assert(sol_inst.victory_dialog.visible, "Victory dialog should be visible upon victory")
	assert(sol_inst.is_game_over, "Game should be marked as game over")

	# 10. Drag & Drop & Hit Test Verification
	# Verify that no face-up card in tableau or waste is blocked by sibling cards
	for col_idx in range(7):
		var col: Array = sol_inst.tableau[col_idx]
		for c in col:
			if c.is_face_up:
				var test_pos: Vector2 = c.global_position + Vector2(50, 14)
				var hit: SolitaireCard = null
				for ci in range(sol_inst.card_layer.get_child_count() - 1, -1, -1):
					var child = sol_inst.card_layer.get_child(ci) as SolitaireCard
					if child and child.visible and child.mouse_filter != Control.MOUSE_FILTER_IGNORE and child.get_global_rect().has_point(test_pos):
						hit = child
						break
				assert(hit == c, "Tableau face-up card must be clickable and draggable")

	# Cleanup test card nodes
	card_ace_spades.queue_free()
	card_2_spades.queue_free()
	card_2_hearts.queue_free()
	card_king_spades.queue_free()
	card_red_king.queue_free()
	card_black_queen.queue_free()
	card_red_queen.queue_free()
	card_black_jack.queue_free()

	sol_inst.queue_free()
	await process_frame
	print("[PASS] Klondike Solitaire Mode tests passed!")

func test_classic_mode() -> void:
	print("[TEST] Testing Classic Domino Mode Scene...")
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	assert(main_scene != null, "Failed to load main.tscn")
	var game_inst: DominoGame = main_scene.instantiate()
	root.add_child(game_inst)
	await process_frame

	assert(game_inst.board != null, "DominoBoard missing in Classic")
	assert(game_inst.menu_btn != null, "MenuBtn missing in Classic TopBar")
	assert(game_inst.new_game_btn != null, "NewGameBtn missing in Classic TopBar")
	assert(game_inst.btn_main_menu != null, "BtnMainMenu missing in GameOverDialog")

	# Test all domino themes load properly
	for th in ["Light", "Dark", "Gingerbread", "Hearts", "Stars"]:
		var tex: Texture2D = ThemeManager.get_tile_texture(6, 6, th)
		assert(tex != null, "Theme texture should exist for %s" % th)
		var empty_tex: Texture2D = ThemeManager.get_empty_texture(th)
		assert(empty_tex != null, "Empty texture should exist for %s" % th)

	game_inst.queue_free()
	await process_frame
	print("[PASS] Classic Domino tests passed!")
