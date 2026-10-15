extends SceneTree

const HoldemGame = preload("res://scripts/HoldemGame.gd")
const GinRummyGame = preload("res://scripts/GinRummyGame.gd")
const GinRummyCard = preload("res://scripts/GinRummyCard.gd")
const PyramidGame = preload("res://scripts/PyramidGame.gd")
const PyramidCard = preload("res://scripts/PyramidCard.gd")
const TriPeaksGame = preload("res://scripts/TriPeaksGame.gd")
const TriPeaksCard = preload("res://scripts/TriPeaksCard.gd")
const SebastopolGame = preload("res://scripts/SebastopolGame.gd")
const SebastopolBoard = preload("res://scripts/SebastopolBoard.gd")
const TileScene = preload("res://scenes/domino_tile.tscn")
const KoiKoiGame = preload("res://scripts/KoiKoiGame.gd")
const HanafudaCard = preload("res://scripts/HanafudaCard.gd")
const HanafudaCardData = preload("res://scripts/HanafudaCardData.gd")
const KoiKoiEvaluator = preload("res://scripts/KoiKoiEvaluator.gd")

func _initialize() -> void:
	print("--- BEGINNING AUTOMATED TESTS ---")
	await test_main_menu()
	await test_koi_koi_mode()
	await test_gin_rummy_mode()
	await test_holdem_mode()
	await test_solitaire_mode()
	await test_pyramid_solitaire_mode()
	await test_tri_peaks_solitaire_mode()
	await test_classic_mode()
	await test_sebastopol_mode()
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

	# Verify simplified, clean Main Menu buttons (Play, Themes, Rules)
	assert(menu_inst.btn_play_game != null, "btn_play_game missing")
	assert("PLAY" in menu_inst.btn_play_game.text, "btn_play_game must be prominent PLAY button")
	assert(menu_inst.btn_themes != null, "btn_themes missing")
	assert(menu_inst.btn_rules != null, "btn_rules missing")

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

	menu_inst.btn_solitaire_draw3.pressed.emit()
	assert(GameSettings.solitaire_draw_count == 3, "Draw 3 button should update settings")
	menu_inst.btn_card_back_green.pressed.emit()
	assert(GameSettings.solitaire_card_back.begins_with("cardBack_green"), "Green back button should update settings")

	# Test Pyramid Solitaire mode buttons in ModeSelectView
	assert(menu_inst.btn_pyramid_pass1 != null, "btn_pyramid_pass1 missing")
	assert(menu_inst.btn_pyramid_pass3 != null, "btn_pyramid_pass3 missing")
	assert(menu_inst.btn_pyramid_pass_inf != null, "btn_pyramid_pass_inf missing")
	assert(menu_inst.btn_start_pyramid != null, "btn_start_pyramid missing")

	menu_inst.btn_pyramid_pass1.pressed.emit()
	assert(GameSettings.pyramid_passes == 1, "Passes 1 button should update settings")
	menu_inst.btn_pyramid_pass_inf.pressed.emit()
	assert(GameSettings.pyramid_passes == 999, "Passes unlimited button should update settings")
	menu_inst.btn_pyramid_pass3.pressed.emit()
	assert(GameSettings.pyramid_passes == 3, "Passes 3 button should update settings")

	# Test Tri Peaks Solitaire mode buttons in ModeSelectView
	assert(menu_inst.btn_tripeaks_pass1 != null, "btn_tripeaks_pass1 missing")
	assert(menu_inst.btn_tripeaks_pass3 != null, "btn_tripeaks_pass3 missing")
	assert(menu_inst.btn_tripeaks_pass_inf != null, "btn_tripeaks_pass_inf missing")
	assert(menu_inst.btn_start_tripeaks != null, "btn_start_tripeaks missing")

	menu_inst.btn_tripeaks_pass1.pressed.emit()
	assert(GameSettings.tripeaks_passes == 1, "Tripeaks Passes 1 button should update settings")
	menu_inst.btn_tripeaks_pass_inf.pressed.emit()
	assert(GameSettings.tripeaks_passes == 999, "Tripeaks Passes unlimited button should update settings")
	menu_inst.btn_tripeaks_pass3.pressed.emit()
	assert(GameSettings.tripeaks_passes == 3, "Tripeaks Passes 3 button should update settings")

	# Test Hold'em mode buttons in ModeSelectView
	assert(menu_inst.btn_holdem_opp1 != null, "btn_holdem_opp1 missing")
	assert(menu_inst.btn_holdem_opp2 != null, "btn_holdem_opp2 missing")
	assert(menu_inst.btn_holdem_opp3 != null, "btn_holdem_opp3 missing")
	assert(menu_inst.btn_chips_500 != null, "btn_chips_500 missing")
	assert(menu_inst.btn_chips_1000 != null, "btn_chips_1000 missing")
	assert(menu_inst.btn_chips_2000 != null, "btn_chips_2000 missing")
	assert(menu_inst.btn_start_holdem != null, "btn_start_holdem missing")

	menu_inst.btn_holdem_opp2.pressed.emit()
	assert(GameSettings.holdem_opponents == 2, "2 AI opponents button should update settings")
	menu_inst.btn_chips_2000.pressed.emit()
	assert(GameSettings.holdem_starting_chips == 2000, "$2,000 chips button should update settings")

	# Test Gin Rummy mode buttons in ModeSelectView
	assert(menu_inst.btn_gin_target_50 != null, "btn_gin_target_50 missing")
	assert(menu_inst.btn_gin_target_100 != null, "btn_gin_target_100 missing")
	assert(menu_inst.btn_gin_target_150 != null, "btn_gin_target_150 missing")
	assert(menu_inst.btn_gin_ai_normal != null, "btn_gin_ai_normal missing")
	assert(menu_inst.btn_gin_ai_sharp != null, "btn_gin_ai_sharp missing")
	assert(menu_inst.btn_start_gin_rummy != null, "btn_start_gin_rummy missing")

	menu_inst.btn_gin_target_150.pressed.emit()
	assert(GameSettings.gin_match_target == 150, "Gin target 150 should update settings")
	menu_inst.btn_gin_ai_sharp.pressed.emit()
	assert(GameSettings.gin_ai_difficulty == "Sharp", "Gin AI Sharp should update settings")

	# Test Koi-Koi mode buttons in ModeSelectView
	assert(menu_inst.btn_koikoi_rounds3 != null, "btn_koikoi_rounds3 missing")
	assert(menu_inst.btn_koikoi_rounds6 != null, "btn_koikoi_rounds6 missing")
	assert(menu_inst.btn_koikoi_rounds12 != null, "btn_koikoi_rounds12 missing")
	assert(menu_inst.btn_koikoi_ai_normal != null, "btn_koikoi_ai_normal missing")
	assert(menu_inst.btn_koikoi_ai_sharp != null, "btn_koikoi_ai_sharp missing")
	assert(menu_inst.btn_start_koikoi != null, "btn_start_koikoi missing")

	menu_inst.btn_koikoi_rounds6.pressed.emit()
	assert(GameSettings.koikoi_rounds == 6, "Koi-Koi rounds 6 should update settings")
	menu_inst.btn_koikoi_rounds12.pressed.emit()
	assert(GameSettings.koikoi_rounds == 12, "Koi-Koi rounds 12 should update settings")
	menu_inst.btn_koikoi_rounds3.pressed.emit()
	assert(GameSettings.koikoi_rounds == 3, "Koi-Koi rounds 3 should update settings")

	menu_inst.btn_koikoi_ai_sharp.pressed.emit()
	assert(GameSettings.koikoi_ai_difficulty == "Sharp", "Koi-Koi AI Sharp should update settings")
	menu_inst.btn_koikoi_ai_normal.pressed.emit()
	assert(GameSettings.koikoi_ai_difficulty == "Normal", "Koi-Koi AI Normal should update settings")

	# Test Sebastopol mode buttons in ModeSelectView
	assert(menu_inst.btn_sebastopol_opp1 != null, "btn_sebastopol_opp1 missing")
	assert(menu_inst.btn_sebastopol_opp2 != null, "btn_sebastopol_opp2 missing")
	assert(menu_inst.btn_sebastopol_opp3 != null, "btn_sebastopol_opp3 missing")
	assert(menu_inst.btn_sebastopol_target_50 != null, "btn_sebastopol_target_50 missing")
	assert(menu_inst.btn_sebastopol_target_100 != null, "btn_sebastopol_target_100 missing")
	assert(menu_inst.btn_sebastopol_target_150 != null, "btn_sebastopol_target_150 missing")
	assert(menu_inst.btn_start_sebastopol != null, "btn_start_sebastopol missing")

	menu_inst.btn_sebastopol_opp2.pressed.emit()
	assert(GameSettings.sebastopol_opponents == 2, "Sebastopol opponents 2 button should update settings")
	menu_inst.btn_sebastopol_opp3.pressed.emit()
	assert(GameSettings.sebastopol_opponents == 3, "Sebastopol opponents 3 button should update settings")

	menu_inst.btn_sebastopol_target_150.pressed.emit()
	assert(GameSettings.sebastopol_match_target == 150, "Sebastopol target 150 button should update settings")
	menu_inst.btn_sebastopol_target_100.pressed.emit()
	assert(GameSettings.sebastopol_match_target == 100, "Sebastopol target 100 button should update settings")

	# Rules modal tabs
	assert(menu_inst.btn_tab_classic != null, "btn_tab_classic missing")
	assert(menu_inst.btn_tab_sebastopol != null, "btn_tab_sebastopol missing")
	assert(menu_inst.btn_tab_solitaire != null, "btn_tab_solitaire missing")
	assert(menu_inst.btn_tab_pyramid != null, "btn_tab_pyramid missing")
	assert(menu_inst.btn_tab_tripeaks != null, "btn_tab_tripeaks missing")
	assert(menu_inst.btn_tab_holdem != null, "btn_tab_holdem missing")
	assert(menu_inst.btn_tab_gin_rummy != null, "btn_tab_gin_rummy missing")
	assert(menu_inst.btn_tab_koikoi != null, "btn_tab_koikoi missing")
	assert(menu_inst.rules_classic_content != null, "rules_classic_content missing")
	assert(menu_inst.rules_sebastopol_content != null, "rules_sebastopol_content missing")
	assert(menu_inst.rules_solitaire_content != null, "rules_solitaire_content missing")
	assert(menu_inst.rules_pyramid_content != null, "rules_pyramid_content missing")
	assert(menu_inst.rules_tripeaks_content != null, "rules_tripeaks_content missing")
	assert(menu_inst.rules_holdem_content != null, "rules_holdem_content missing")
	assert(menu_inst.rules_gin_rummy_content != null, "rules_gin_rummy_content missing")
	assert(menu_inst.rules_koikoi_content != null, "rules_koikoi_content missing")

	menu_inst.btn_tab_sebastopol.pressed.emit()
	assert(menu_inst.rules_sebastopol_content.visible, "Sebastopol rules should be visible when tab clicked")
	assert(not menu_inst.rules_classic_content.visible, "Classic rules should be hidden")

	menu_inst.btn_tab_solitaire.pressed.emit()
	assert(menu_inst.rules_solitaire_content.visible, "Solitaire rules should be visible when tab clicked")
	assert(not menu_inst.rules_sebastopol_content.visible, "Sebastopol rules should be hidden")

	menu_inst.btn_tab_pyramid.pressed.emit()
	assert(menu_inst.rules_pyramid_content.visible, "Pyramid rules should be visible when tab clicked")
	assert(not menu_inst.rules_solitaire_content.visible, "Solitaire rules should be hidden")

	menu_inst.btn_tab_tripeaks.pressed.emit()
	assert(menu_inst.rules_tripeaks_content.visible, "Tri Peaks rules should be visible when tab clicked")
	assert(not menu_inst.rules_pyramid_content.visible, "Pyramid rules should be hidden")

	menu_inst.btn_tab_holdem.pressed.emit()
	assert(menu_inst.rules_holdem_content.visible, "Hold'em rules should be visible when tab clicked")
	assert(not menu_inst.rules_tripeaks_content.visible, "Tri Peaks rules should be hidden")

	menu_inst.btn_tab_gin_rummy.pressed.emit()
	assert(menu_inst.rules_gin_rummy_content.visible, "Gin Rummy rules should be visible when tab clicked")
	assert(not menu_inst.rules_holdem_content.visible, "Hold'em rules should be hidden")

	menu_inst.btn_tab_koikoi.pressed.emit()
	assert(menu_inst.rules_koikoi_content.visible, "Koi-Koi rules should be visible when tab clicked")
	assert(not menu_inst.rules_gin_rummy_content.visible, "Gin Rummy rules should be hidden")

	# Test ModeSelectView Category Filtering & Quick Navigation
	assert(menu_inst.btn_cat_all != null, "btn_cat_all missing")
	assert(menu_inst.btn_cat_domino != null, "btn_cat_domino missing")
	assert(menu_inst.btn_cat_solitaire != null, "btn_cat_solitaire missing")
	assert(menu_inst.btn_cat_cards != null, "btn_cat_cards missing")
	assert(menu_inst.btn_scroll_left != null, "btn_scroll_left missing")
	assert(menu_inst.btn_scroll_right != null, "btn_scroll_right missing")
	assert(menu_inst.btn_themes_quick != null, "btn_themes_quick missing")
	assert(menu_inst.btn_rules_quick != null, "btn_rules_quick missing")

	# Test Domino category filter
	menu_inst.btn_cat_domino.pressed.emit()
	assert(menu_inst.card_classic.visible, "Classic card should be visible in Domino category")
	assert(menu_inst.card_sebastopol.visible, "Sebastopol card should be visible in Domino category")
	assert(not menu_inst.card_solitaire.visible, "Solitaire card should be hidden in Domino category")
	assert(not menu_inst.card_holdem.visible, "Holdem card should be hidden in Domino category")
	assert(not menu_inst.card_koikoi.visible, "Koi-Koi card should be hidden in Domino category")

	# Test Solitaire category filter
	menu_inst.btn_cat_solitaire.pressed.emit()
	assert(menu_inst.card_solitaire.visible, "Klondike card should be visible in Solitaire category")
	assert(menu_inst.card_pyramid.visible, "Pyramid card should be visible in Solitaire category")
	assert(menu_inst.card_tripeaks.visible, "TriPeaks card should be visible in Solitaire category")
	assert(not menu_inst.card_classic.visible, "Classic card should be hidden in Solitaire category")
	assert(not menu_inst.card_koikoi.visible, "Koi-Koi card should be hidden in Solitaire category")

	# Test Cards category filter
	menu_inst.btn_cat_cards.pressed.emit()
	assert(menu_inst.card_holdem.visible, "Holdem card should be visible in Cards category")
	assert(menu_inst.card_gin_rummy.visible, "Gin Rummy card should be visible in Cards category")
	assert(menu_inst.card_koikoi.visible, "Koi-Koi card should be visible in Cards category")
	assert(not menu_inst.card_solitaire.visible, "Solitaire card should be hidden in Cards category")

	# Test All category filter
	menu_inst.btn_cat_all.pressed.emit()
	assert(menu_inst.card_classic.visible, "Classic card should be visible in All category")
	assert(menu_inst.card_solitaire.visible, "Solitaire card should be visible in All category")
	assert(menu_inst.card_holdem.visible, "Holdem card should be visible in All category")
	assert(menu_inst.card_gin_rummy.visible, "Gin Rummy card should be visible in All category")
	assert(menu_inst.card_koikoi.visible, "Koi-Koi card should be visible in All category")

	# Test Quick Navigation buttons in ModeSelectView
	menu_inst.btn_themes_quick.pressed.emit()
	assert(menu_inst.themes_modal.visible, "Themes modal should open from quick navigation button")
	menu_inst.btn_close_themes.pressed.emit()
	await create_timer(0.2).timeout
	assert(not menu_inst.themes_modal.visible, "Themes modal should close via close button")

	menu_inst.btn_rules_quick.pressed.emit()
	assert(menu_inst.rules_modal.visible, "Rules modal should open from quick navigation button")
	menu_inst.btn_close_rules.pressed.emit()
	await create_timer(0.2).timeout
	assert(not menu_inst.rules_modal.visible, "Rules modal should close via close button")

	# Test Carousel scroll buttons trigger without error
	menu_inst.btn_scroll_right.pressed.emit()
	menu_inst.btn_scroll_left.pressed.emit()

	menu_inst.queue_free()
	await process_frame
	print("[PASS] Main Menu tests passed!")

func test_koi_koi_mode() -> void:
	print("[TEST] Testing Koi-Koi Mode Scene & Logic...")
	var koi_scene: PackedScene = load("res://scenes/koi_koi.tscn")
	assert(koi_scene != null, "Failed to load koi_koi.tscn")
	var koi_inst: KoiKoiGame = koi_scene.instantiate()
	koi_inst.is_instant_mode = true
	root.add_child(koi_inst)
	await process_frame

	# Verify dealing
	assert(koi_inst.player_hand.size() == 8, "Player must start with 8 cards")
	assert(koi_inst.ai_hand.size() == 8, "AI must start with 8 cards")
	assert(koi_inst.field_cards.size() == 8, "Field must start with 8 cards")
	assert(koi_inst.deck_data.size() == 24, "Deck must start with 24 cards")

	# Verify card back plain color #1f2326
	var c_ai: HanafudaCard = koi_inst.ai_hand[0]
	assert(not c_ai.is_face_up, "AI hand card must be face down")
	assert(c_ai.back_panel != null, "back_panel must exist on card")
	var sb = c_ai.back_panel.get_theme_stylebox("panel") as StyleBoxFlat
	assert(sb != null and sb.bg_color == Color("#1f2326"), "Card back must use plain color #1f2326")

	# Test player playing a card from hand
	var c_play: HanafudaCard = koi_inst.player_hand[0]
	koi_inst._on_card_clicked(c_play)
	assert(koi_inst.player_hand.size() == 7, "Player hand should decrease to 7 after play")

	# Test Yaku evaluation & modal
	var sample_eval = {
		"has_yaku": true,
		"total_points": 5,
		"yaku_list": [{"name": "Red Poetry Ribbons (Akatan)", "points": 5}]
	}
	koi_inst._show_player_koikoi_modal(sample_eval)
	assert(koi_inst.koikoi_modal.visible, "Koi-Koi modal should be displayed")

	koi_inst._on_player_called_shoubu()
	assert(not koi_inst.koikoi_modal.visible, "Koi-Koi modal should close on Stop")
	assert(koi_inst.round_dialog.visible, "Round dialog should appear")

	koi_inst.queue_free()
	await process_frame
	print("[PASS] Koi-Koi Mode tests passed!")

func test_gin_rummy_mode() -> void:
	print("[TEST] Testing Gin Rummy Mode Scene & Logic...")
	var gin_scene: PackedScene = load("res://scenes/gin_rummy.tscn")
	assert(gin_scene != null, "Failed to load gin_rummy.tscn")
	var gin_inst: GinRummyGame = gin_scene.instantiate()
	gin_inst.is_instant_mode = true
	root.add_child(gin_inst)
	await process_frame

	assert(gin_inst.player_cards.size() == 10, "Player must start with 10 cards")
	assert(gin_inst.ai_cards.size() == 10, "AI must start with 10 cards")
	assert(gin_inst.discard_pile.size() == 1, "Discard pile should start with 1 card")
	assert(gin_inst.stock_pile.size() == 31, "Stock pile should have 31 cards")

	# Test player draw from stock
	gin_inst.is_player_turn = true
	gin_inst.current_phase = GinRummyGame.TurnPhase.DRAW
	gin_inst._on_player_draw_stock()
	assert(gin_inst.player_cards.size() == 11, "Player should have 11 cards after drawing")
	assert(gin_inst.current_phase == GinRummyGame.TurnPhase.DISCARD, "Phase should be DISCARD")

	# Test player discard
	var c_discard: GinRummyCard = gin_inst.player_cards[0]
	gin_inst._on_player_card_clicked(c_discard)
	assert(gin_inst.selected_card == c_discard, "Card must be selected")
	gin_inst._on_player_discard_selected()
	assert(gin_inst.player_cards.size() == 10, "Player should have 10 cards after discarding")

	# Test AI turn
	gin_inst.is_player_turn = false
	gin_inst.current_phase = GinRummyGame.TurnPhase.DRAW
	gin_inst._execute_ai_turn()
	assert(gin_inst.ai_cards.size() == 10, "AI should finish turn with 10 cards")

	# Test showdown display
	gin_inst._finalize_hand_with_knock(true, false)
	assert(gin_inst.showdown_modal.visible == true, "Showdown modal should be displayed")

	gin_inst.queue_free()
	await process_frame
	print("[PASS] Gin Rummy Mode tests passed!")

func test_holdem_mode() -> void:
	print("[TEST] Testing Texas Hold'em Mode Scene & Logic...")
	var holdem_scene: PackedScene = load("res://scenes/holdem.tscn")
	assert(holdem_scene != null, "Failed to load holdem.tscn")
	var holdem_inst: HoldemGame = holdem_scene.instantiate()
	holdem_inst.is_instant_mode = true
	root.add_child(holdem_inst)
	await process_frame

	assert(holdem_inst.table_felt != null, "Table felt missing")
	assert(holdem_inst.pot_label != null, "Pot label missing")
	assert(holdem_inst.community_container != null, "Community container missing")
	assert(holdem_inst.community_container.get_child_count() == 5, "Expected 5 community slots")
	assert(holdem_inst.players.size() >= 2, "Expected at least 2 players")

	var human = holdem_inst.players[0]
	assert(human["is_human"] == true, "Player 0 must be human")
	assert(human["cards"].size() == 2, "Human should have 2 hole cards")
	assert(human["cards"][0].is_face_up == true, "Human hole card must be face up")

	# Verify Fold
	holdem_inst._on_user_fold()
	assert(human["is_folded"] == true, "Human should be folded after fold")

	# Clean up and instantiate fresh instance for community dealing & showdown
	holdem_inst.queue_free()
	await process_frame

	var holdem_deal_inst: HoldemGame = holdem_scene.instantiate()
	holdem_deal_inst.is_instant_mode = true
	root.add_child(holdem_deal_inst)
	holdem_deal_inst._clean_up_cards()
	assert(holdem_deal_inst.community_cards.size() == 0, "Community cards start empty on fresh deal")

	# Verify community dealing
	holdem_deal_inst._deal_community_cards(3)
	assert(holdem_deal_inst.community_cards.size() == 3, "Flop dealt 3 cards")
	holdem_deal_inst._deal_community_cards(1)
	assert(holdem_deal_inst.community_cards.size() == 4, "Turn dealt 4th card")
	holdem_deal_inst._deal_community_cards(1)
	assert(holdem_deal_inst.community_cards.size() == 5, "River dealt 5th card")

	# Verify Showdown
	holdem_deal_inst._handle_showdown()
	assert(holdem_deal_inst.showdown_banner.visible == true, "Showdown banner displayed")

	holdem_deal_inst.queue_free()
	await process_frame
	print("[PASS] Texas Hold'em Mode tests passed!")


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

	# 11. Visual Table & Hover Glow Verification
	var table_bg = sol_inst.get_node_or_null("TableBackground") as Panel
	assert(table_bg != null, "TableBackground node should exist")
	var table_style = table_bg.get_theme_stylebox("panel") as StyleBoxFlat
	assert(table_style != null and is_equal_approx(table_style.bg_color.r, 0.08) and is_equal_approx(table_style.bg_color.g, 0.24),
		"Table should have classic green felt stylebox")
	assert(table_style.border_width_left == 12, "Table should have 12px wood rim border")

	for s in [sol_inst.stock_slot, sol_inst.waste_slot, sol_inst.foundation_slots[0], sol_inst.tableau_slots[0]]:
		var sb = s.get_theme_stylebox("panel") as StyleBoxFlat
		assert(sb.border_width_left >= 2, "Slot border width must be >= 2px")
		assert(sb.border_color.a >= 0.4, "Slot border color alpha must be >= 0.4")
		assert(s.has_node("HighlightGlow"), "Slot must have HighlightGlow child")

	# Test card hover glow
	var top_card: SolitaireCard = sol_inst.all_cards[0]
	top_card._on_mouse_entered()
	assert(top_card.highlight_glow.visible, "Card glow should be active on mouse enter")
	top_card._on_mouse_exited()
	assert(not top_card.highlight_glow.visible, "Card glow should be inactive on mouse exit")

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

func test_pyramid_solitaire_mode() -> void:
	print("[TEST] Testing Pyramid Solitaire Mode Scene & Logic...")
	var pyr_scene: PackedScene = load("res://scenes/pyramid_solitaire.tscn")
	assert(pyr_scene != null, "Failed to load pyramid_solitaire.tscn")
	var game: PyramidGame = pyr_scene.instantiate()
	game.is_instant_mode = true
	root.add_child(game)
	await process_frame

	# 1. UI nodes check
	assert(game.card_layer != null, "card_layer missing")
	assert(game.stock_slot != null, "stock_slot missing")
	assert(game.waste_slot != null, "waste_slot missing")
	assert(game.discard_slot != null, "discard_slot missing")
	assert(game.btn_undo != null, "btn_undo missing")
	assert(game.btn_hint != null, "btn_hint missing")
	assert(game.btn_restart != null, "btn_restart missing")
	assert(game.btn_menu != null, "btn_menu missing")

	# 2. Layout and card count check
	assert(game.all_cards.size() == 52, "Expected 52 cards")
	assert(game.stock.size() == 24, "Expected 24 stock cards")
	assert(game.waste.size() == 0, "Waste starts empty")
	assert(game.discard.size() == 0, "Discard starts empty")

	var total_pyr_cards: int = 0
	for r in range(7):
		assert(game.pyramid_rows[r].size() == r + 1, "Row %d size" % r)
		for c in range(r + 1):
			var card: PyramidCard = game.pyramid_rows[r][c]
			assert(card != null, "Card at (%d, %d)" % [r, c])
			assert(card.is_face_up == true, "Must be face-up")
			total_pyr_cards += 1
			if r == 6:
				assert(card.is_exposed == true, "Row 6 exposed")
			else:
				assert(card.is_exposed == false, "Rows 0..5 covered")
	assert(total_pyr_cards == 28, "Pyramid has 28 cards")

	# 3. Stock draw and undo
	game._on_stock_clicked()
	assert(game.stock.size() == 23, "Stock decreased to 23")
	assert(game.waste.size() == 1, "Waste has 1 card")
	assert(game.waste.back().is_exposed == true, "Top waste card is exposed")

	game._on_undo_clicked()
	assert(game.stock.size() == 24, "Stock restored to 24")
	assert(game.waste.size() == 0, "Waste empty after undo")

	# 4. King solo discard
	var test_king: PyramidCard = game.PyramidCardScene.instantiate()
	test_king.setup("Spades", 13, true)
	test_king.set_exposed(true)
	test_king.pile_type = "pyramid"
	test_king.row = 6
	test_king.col = 0
	game.pyramid_rows[6][0] = test_king
	game.card_layer.add_child(test_king)

	var score_before: int = game.score
	game._on_card_clicked(test_king)
	assert(game.pyramid_rows[6][0] == null, "King removed from pyramid")
	assert(game.discard.has(test_king), "King added to discard")
	assert(game.score == score_before + 10, "Score +10 for King")

	game._on_undo_clicked()
	assert(game.pyramid_rows[6][0] == test_king, "King restored after undo")
	assert(not game.discard.has(test_king), "King removed from discard")

	# 5. Pair sum to 13
	var card_8: PyramidCard = game.PyramidCardScene.instantiate()
	card_8.setup("Hearts", 8, true)
	card_8.set_exposed(true)
	card_8.pile_type = "pyramid"
	card_8.row = 6
	card_8.col = 1
	game.pyramid_rows[6][1] = card_8
	game.card_layer.add_child(card_8)

	var card_5: PyramidCard = game.PyramidCardScene.instantiate()
	card_5.setup("Diamonds", 5, true)
	card_5.set_exposed(true)
	card_5.pile_type = "pyramid"
	card_5.row = 6
	card_5.col = 2
	game.pyramid_rows[6][2] = card_5
	game.card_layer.add_child(card_5)

	game._on_card_clicked(card_8)
	assert(game.selected_card == card_8, "card_8 selected")
	game._on_card_clicked(card_5)
	assert(game.selected_card == null, "Match completed and selection cleared")
	assert(game.pyramid_rows[6][1] == null, "card_8 removed")
	assert(game.pyramid_rows[6][2] == null, "card_5 removed")

	game._on_undo_clicked()
	assert(game.pyramid_rows[6][1] == card_8, "card_8 restored after undo")
	assert(game.pyramid_rows[6][2] == card_5, "card_5 restored after undo")

	# 6. Hint feature
	game._on_hint_clicked()
	assert(game.toast_panel.visible == true, "Hint toast visible")

	# 7. Victory condition
	for r in range(7):
		for c in range(r + 1):
			game.pyramid_rows[r][c] = null
	game._check_victory()
	assert(game.is_game_over == true, "Game is marked over")
	assert(game.victory_dialog.visible == true, "Victory dialog shown")

	# Clean up
	test_king.queue_free()
	card_8.queue_free()
	card_5.queue_free()
	game.queue_free()
	await process_frame
	print("[PASS] Pyramid Solitaire Mode tests passed!")

func test_tri_peaks_solitaire_mode() -> void:
	print("[TEST] Testing Tri Peaks Solitaire Mode Scene & Logic...")
	var tri_scene: PackedScene = load("res://scenes/tri_peaks_solitaire.tscn")
	assert(tri_scene != null, "Failed to load tri_peaks_solitaire.tscn")
	var game: TriPeaksGame = tri_scene.instantiate()
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
	assert(game.all_cards.size() == 52, "Expected 52 total cards generated")
	assert(game.stock.size() == 23, "Expected 23 cards in stock, got %d" % game.stock.size())
	assert(game.waste.size() == 1, "Expected 1 initial waste card, got %d" % game.waste.size())
	assert(game.waste.back().is_face_up == true, "Initial waste card must be face-up")

	var row_expected: Array[int] = [3, 6, 9, 10]
	var total_tableau_cards: int = 0
	for r in range(4):
		assert(game.tableau_rows[r].size() == row_expected[r], "Row %d expected %d cards" % [r, row_expected[r]])
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

	assert(game.can_play_to_waste(card_rank_8) == true, "8 can play on 7 (+1)")
	assert(game.can_play_to_waste(card_rank_6) == true, "6 can play on 7 (-1)")
	assert(game.can_play_to_waste(card_rank_9) == false, "9 cannot play on 7 (+2)")

	# Wrap around
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

	assert(game.can_play_to_waste(card_ace) == true, "Ace can play on King with wrap-around")

	# 5. Test Playing Card, Streak Building, and Undo
	game.current_streak = 0
	game.score = 0
	var prev_score: int = game.score
	var prev_moves: int = game.moves_count

	# Place Ace on waste, and prepare rank 2 to play
	game.waste.clear()
	game.waste.append(card_ace)

	var card_2: TriPeaksCard = game.TriPeaksCardScene.instantiate()
	card_2.setup("Hearts", 2, true)
	card_2.set_exposed(true)
	card_2.pile_type = "tableau"
	card_2.row = 3
	card_2.col = 2
	game.tableau_rows[3][2] = card_2
	game.card_layer.add_child(card_2)

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
	game._play_card_to_waste(peak_card)
	assert(game.peaks_cleared == 1, "peaks_cleared should be 1")
	assert(game.score == score_before_peak + 20 + 150, "Peak 1 bonus should award +150 plus streak")

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

	game._on_undo_clicked()
	assert(game.stock.size() == stock_count_before, "Stock restored after undo")
	assert(game.current_streak == 5, "Streak restored after undo")

	# 8. Test Stock Recycle
	game.stock.clear()
	game.stock_passes_used = 0
	game.max_stock_passes = 3
	for i in range(4):
		var extra: TriPeaksCard = game.TriPeaksCardScene.instantiate()
		extra.setup("Hearts", 4 + i, true)
		extra.pile_type = "waste"
		game.waste.append(extra)
		game.card_layer.add_child(extra)

	var waste_count_before: int = game.waste.size()
	game._on_stock_clicked()
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
	waste_king.queue_free()
	card_ace.queue_free()
	card_2.queue_free()
	card_3.queue_free()
	peak_card.queue_free()
	game.queue_free()
	await process_frame
	print("[PASS] Tri Peaks Solitaire Mode tests passed!")

func test_sebastopol_mode() -> void:
	print("[TEST] Testing Sebastopol Domino Mode (The Star)...")

	# 1. SebastopolBoard rules & star mechanics
	var board := SebastopolBoard.new()
	root.add_child(board)
	await process_frame

	assert(board.is_empty() == true, "Board must start empty")
	assert(board.is_star_complete == false, "Star should not be complete initially")
	assert(board.get_filled_arms_count() == 0, "No arms filled initially")
	assert(board.get_empty_arms().size() == 4, "All 4 arms empty initially")

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

	assert(board.can_play(tile_6_6) == true, "[6-6] must be able to open")
	assert(board.can_play(tile_6_5) == false, "Non [6-6] cannot open empty board")
	board.place_tile(tile_6_6, "center")
	assert(board.spinner_tile == tile_6_6, "Spinner set to [6-6]")
	assert(board.is_star_complete == false, "Star not complete with only spinner")

	# Can only play on empty star arms
	assert(board.can_play(tile_6_5) == true, "[6-5] can play on star")
	assert(board.can_play(tile_5_2) == false, "[5-2] cannot play during star phase")
	board.place_tile(tile_6_5, "north")
	assert(board.get_filled_arms_count() == 1, "1 arm filled")

	# Cannot extend north arm before 4 arms filled
	assert(board.can_play(tile_5_2) == false, "Cannot extend arm before star complete")

	board.place_tile(tile_6_4, "south")
	board.place_tile(tile_6_3, "east")
	assert(board.get_filled_arms_count() == 3, "3 arms filled")

	var star_sig: Array[bool] = [false]
	board.star_completed.connect(func(): star_sig[0] = true)
	board.place_tile(tile_6_2, "west")
	assert(board.get_filled_arms_count() == 4, "All 4 arms filled")
	assert(board.is_star_complete == true, "Star complete")
	assert(star_sig[0] == true, "star_completed signal emitted")

	# Now in open phase, [5-2] and [4-1] can be played
	assert(board.can_play(tile_5_2) == true, "[5-2] can play on open arms")
	assert(board.can_play(tile_4_1) == true, "[4-1] can play on South(4)")
	board.place_tile(tile_4_1, "south")
	assert(board.get_open_val("south") == 1, "South open val updated to 1")

	# Undo
	assert(board.can_undo() == true, "Can undo")
	var undone: DominoTile = board.undo_last_placement()
	assert(undone == tile_4_1, "Undone tile is tile_4_1")
	assert(board.get_open_val("south") == 4, "South open val restored to 4")

	tile_6_6.queue_free()
	tile_6_5.queue_free()
	tile_6_4.queue_free()
	tile_6_3.queue_free()
	tile_6_2.queue_free()
	tile_5_2.queue_free()
	tile_4_1.queue_free()
	board.queue_free()
	await process_frame

	# 2. SebastopolGame Scene & Flow
	var seb_scene: PackedScene = load("res://scenes/sebastopol.tscn")
	assert(seb_scene != null, "scenes/sebastopol.tscn should load")

	var game: SebastopolGame = seb_scene.instantiate()
	game.is_instant_mode = true
	root.add_child(game)
	await process_frame

	assert(game.board != null, "board missing")
	assert(game.turn_label != null, "turn_label missing")
	assert(game.star_status_label != null, "star_status_label missing")
	assert(game.pass_btn != null, "pass_btn missing")
	assert(game.btn_play_north != null, "btn_play_north missing")
	assert(game.btn_play_south != null, "btn_play_south missing")
	assert(game.btn_play_east != null, "btn_play_east missing")
	assert(game.btn_play_west != null, "btn_play_west missing")
	assert(game.setup_modal != null, "setup_modal missing")

	# 4 players dealt 7 tiles each
	assert(game.players.size() == 4, "Expected 4 players in standard Sebastopol")
	var total_dealt: int = 0
	for p in game.players:
		assert(p.hand_size() == 7, "Each player starts with 7 tiles")
		total_dealt += p.hand_size()
	assert(total_dealt == 28, "All 28 tiles dealt")
	assert(game.boneyard.is_empty() == true, "Boneyard empty in 4-player Sebastopol")

	# Starter holds [6-6]
	var starter: Player = game.players[game.current_player_idx]
	var has_6_6: bool = false
	for t in starter.hand:
		if t.top_val == 6 and t.bottom_val == 6:
			has_6_6 = true
			break
	assert(has_6_6 == true, "Starter must hold [6-6]")

	# First move: starter plays [6-6]
	if starter.is_human:
		for t in starter.hand:
			if t.top_val == 6 and t.bottom_val == 6:
				game._on_tile_clicked(t)
				break
	else:
		game._start_ai_turn()

	assert(game.board.is_empty() == false, "Board should have spinner placed")
	assert(game.board.spinner_tile.top_val == 6 and game.board.spinner_tile.bottom_val == 6, "Center is [6-6]")

	# Passing flow
	var prev_board_count: int = game.board.placed_tiles.size()
	game.current_state = SebastopolGame.State.PLAYING
	game.current_player_idx = 0
	game._on_pass_clicked()
	assert(game.board.placed_tiles.size() > prev_board_count or game.consecutive_passes >= 1, "Passing flow progresses game")

	# Domino victory scoring
	var winner: Player = game.players[0]
	winner.clear_hand()
	game._end_round_winner(winner, false)
	assert(game.current_state == SebastopolGame.State.ROUND_OVER, "State is ROUND_OVER")
	assert(winner.round_score > 0, "Winner receives points from opponents")
	assert(game.game_over_panel.visible == true, "GameOver panel visible")

	# Setup modal
	game.open_setup_modal()
	assert(game.setup_modal.visible == true, "Setup modal visible")
	game._set_setup_opponents(2)
	assert(game.num_opponents == 2, "Opponents set to 2")
	game._set_setup_target(150)
	assert(game.match_target == 150, "Match target set to 150")
	game.close_setup_modal()
	assert(game.setup_modal.visible == false, "Setup modal closed")

	game.queue_free()
	await process_frame
	print("[PASS] Sebastopol Domino Mode tests passed!")



