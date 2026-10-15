extends SceneTree

const HanafudaCardData = preload("res://scripts/HanafudaCardData.gd")
const KoiKoiEvaluator = preload("res://scripts/KoiKoiEvaluator.gd")
const KoiKoiAI = preload("res://scripts/KoiKoiAI.gd")
const KoiKoiGame = preload("res://scripts/KoiKoiGame.gd")
const HanafudaCard = preload("res://scripts/HanafudaCard.gd")

func _initialize() -> void:
	print("--- TESTING KOI-KOI HANAFUDA LOGIC & SCENE ---")
	test_deck_definitions()
	test_card_back_color()
	test_yaku_evaluator()
	test_instant_hands()
	test_multipliers()
	test_ai_logic()
	await test_koi_koi_scene()
	print("--- KOI-KOI TESTS COMPLETED SUCCESSFULLY ---")
	quit(0)

func test_deck_definitions() -> void:
	print("[TEST] Testing Deck Definitions & Composition...")
	var deck: Array[Dictionary] = HanafudaCardData.get_deck_definitions()
	assert(deck.size() == 48, "Deck must have 48 cards, got %d" % deck.size())

	var hikari_count: int = 0
	var tane_count: int = 0
	var tanzaku_count: int = 0
	var kasu_count: int = 0
	var month_counts: Dictionary = {}

	for card in deck:
		var m: int = card["month"]
		assert(m >= 1 and m <= 12, "Month must be between 1 and 12")
		month_counts[m] = month_counts.get(m, 0) + 1

		# Verify texture resource exists
		assert(ResourceLoader.exists(card["texture_path"]), "Texture must exist: %s" % card["texture_path"])

		match card["card_type"]:
			HanafudaCardData.CardType.HIKARI: hikari_count += 1
			HanafudaCardData.CardType.TANE: tane_count += 1
			HanafudaCardData.CardType.TANZAKU: tanzaku_count += 1
			HanafudaCardData.CardType.KASU: kasu_count += 1

	assert(hikari_count == 5, "Expected 5 Bright (Hikari) cards, got %d" % hikari_count)
	assert(tane_count == 9, "Expected 9 Animal (Tane) cards, got %d" % tane_count)
	assert(tanzaku_count == 10, "Expected 10 Ribbon (Tanzaku) cards, got %d" % tanzaku_count)
	assert(kasu_count == 24, "Expected 24 Plain (Kasu) cards, got %d" % kasu_count)

	for m in range(1, 13):
		assert(month_counts[m] == 4, "Month %d must have exactly 4 cards" % m)
	print("  [PASS] Deck has exact 48 cards (5 Hikari, 9 Tane, 10 Tanzaku, 24 Kasu).")

func test_card_back_color() -> void:
	print("[TEST] Testing Card Back Color #1f2326...")
	assert(HanafudaCardData.CARD_BACK_COLOR == Color("#1f2326"), "Card back color must be #1f2326")
	assert(ResourceLoader.exists(HanafudaCardData.CARD_BACK_PATH), "Back SVG must exist: %s" % HanafudaCardData.CARD_BACK_PATH)
	print("  [PASS] Card back plain color #1f2326 verified.")

func test_yaku_evaluator() -> void:
	print("[TEST] Testing Yaku Combinations & Scoring...")
	var deck: Array[Dictionary] = HanafudaCardData.get_deck_definitions()

	# Find specific cards
	var crane: Dictionary
	var curtain: Dictionary
	var moon: Dictionary
	var rainman: Dictionary
	var phoenix: Dictionary
	var boar: Dictionary
	var deer: Dictionary
	var butterfly: Dictionary
	var sake_cup: Dictionary
	var akatan_cards: Array[Dictionary] = []
	var aotan_cards: Array[Dictionary] = []
	var kasu_cards: Array[Dictionary] = []

	for c in deck:
		if c.get("is_crane", false): crane = c
		if c.get("is_curtain", false): curtain = c
		if c.get("is_moon", false): moon = c
		if c.get("is_rainman", false): rainman = c
		if c.get("is_phoenix", false): phoenix = c
		if c.get("is_boar", false): boar = c
		if c.get("is_deer", false): deer = c
		if c.get("is_butterfly", false): butterfly = c
		if c.get("is_sake_cup", false): sake_cup = c
		if c.get("tanzaku_type") == HanafudaCardData.TanzakuType.AKATAN: akatan_cards.append(c)
		if c.get("tanzaku_type") == HanafudaCardData.TanzakuType.AOTAN: aotan_cards.append(c)
		if c.get("is_kasu", false): kasu_cards.append(c)

	# 1. Five Brights (Goko) = 10 pts
	var all_brights = [crane, curtain, moon, rainman, phoenix]
	var eval_goko = KoiKoiEvaluator.evaluate_yaku(all_brights, false)
	assert(eval_goko.total_points == 10, "Goko must be 10 points")

	# 2. Four Brights (Shiko) = 8 pts
	var four_brights = [crane, curtain, moon, phoenix]
	var eval_shiko = KoiKoiEvaluator.evaluate_yaku(four_brights, false)
	assert(eval_shiko.total_points == 8, "Shiko must be 8 points")

	# 3. Rainy Four Brights (Ame-Shiko) = 7 pts
	var ame_brights = [crane, curtain, rainman, phoenix]
	var eval_ame = KoiKoiEvaluator.evaluate_yaku(ame_brights, false)
	assert(eval_ame.total_points == 7, "Ame-Shiko must be 7 points")

	# 4. Three Brights (Sanko) = 5 pts
	var sanko_cards = [crane, curtain, moon]
	var eval_sanko = KoiKoiEvaluator.evaluate_yaku(sanko_cards, false)
	assert(eval_sanko.total_points == 5, "Sanko must be 5 points")

	# Rainy 3 Brights is NOT Sanko
	var rainy_3 = [crane, curtain, rainman]
	var eval_rainy_3 = KoiKoiEvaluator.evaluate_yaku(rainy_3, false)
	assert(eval_rainy_3.total_points == 0, "3 Brights with Rainman should not award points")

	# 5. Inoshikacho (Boar-Deer-Butterflies) = 5 pts
	var inoshika = [boar, deer, butterfly]
	var eval_ino = KoiKoiEvaluator.evaluate_yaku(inoshika, false)
	assert(eval_ino.total_points == 5, "Inoshikacho must be 5 points")

	# Inoshikacho + 1 extra Tane = 6 pts
	var inoshika_extra = [boar, deer, butterfly, sake_cup]
	var eval_ino_extra = KoiKoiEvaluator.evaluate_yaku(inoshika_extra, false)
	assert(eval_ino_extra.total_points == 6, "Inoshikacho + 1 extra Tane must be 6 points")

	# 6. Akatan = 5 pts
	var eval_akatan = KoiKoiEvaluator.evaluate_yaku(akatan_cards, false)
	assert(eval_akatan.total_points == 5, "Akatan must be 5 points")

	# 7. Aotan = 5 pts
	var eval_aotan = KoiKoiEvaluator.evaluate_yaku(aotan_cards, false)
	assert(eval_aotan.total_points == 5, "Aotan must be 5 points")

	# 8. Akatan & Aotan = 10 pts
	var both_ribbons = []
	both_ribbons.append_array(akatan_cards)
	both_ribbons.append_array(aotan_cards)
	var eval_both = KoiKoiEvaluator.evaluate_yaku(both_ribbons, false)
	assert(eval_both.total_points == 10, "Akatan & Aotan combined must be 10 points")

	# 9. Hanami-de-Ippai (Curtain + Sake Cup) = 5 pts
	var hanami = [curtain, sake_cup]
	var eval_hanami = KoiKoiEvaluator.evaluate_yaku(hanami, true)
	assert(eval_hanami.total_points == 5, "Hanami must be 5 points")

	# 10. Tsukimi-de-Ippai (Moon + Sake Cup) = 5 pts
	var tsukimi = [moon, sake_cup]
	var eval_tsukimi = KoiKoiEvaluator.evaluate_yaku(tsukimi, true)
	assert(eval_tsukimi.total_points == 5, "Tsukimi must be 5 points")

	# 11. Kasu (10 Plains) = 1 pt, (12 Plains) = 3 pts
	var ten_kasu = kasu_cards.slice(0, 10)
	var eval_kasu_10 = KoiKoiEvaluator.evaluate_yaku(ten_kasu, false)
	assert(eval_kasu_10.total_points == 1, "10 Kasu must be 1 point")

	var twelve_kasu = kasu_cards.slice(0, 12)
	var eval_kasu_12 = KoiKoiEvaluator.evaluate_yaku(twelve_kasu, false)
	assert(eval_kasu_12.total_points == 3, "12 Kasu must be 3 points")

	print("  [PASS] All Yaku evaluated accurately.")

func test_instant_hands() -> void:
	print("[TEST] Testing Teshi and Kuttsuki hand recognition...")
	var deck: Array[Dictionary] = HanafudaCardData.get_deck_definitions()

	# Teshi: 4 cards of Month 1
	var teshi_hand: Array[Dictionary] = []
	for c in deck:
		if c["month"] == 1:
			teshi_hand.append(c)
	# Fill with 4 others from Month 2
	for c in deck:
		if c["month"] == 2 and teshi_hand.size() < 8:
			teshi_hand.append(c)

	assert(KoiKoiEvaluator.check_teshi(teshi_hand), "Teshi hand must be detected")

	# Kuttsuki: 4 pairs of 2 cards each (Months 1, 2, 3, 4)
	var kuttsuki_hand: Array[Dictionary] = []
	for m in [1, 2, 3, 4]:
		var count: int = 0
		for c in deck:
			if c["month"] == m and count < 2:
				kuttsuki_hand.append(c)
				count += 1

	assert(KoiKoiEvaluator.check_kuttsuki(kuttsuki_hand), "Kuttsuki hand must be detected")
	print("  [PASS] Teshi & Kuttsuki recognized.")

func test_multipliers() -> void:
	print("[TEST] Testing Score Multipliers (7+ rule & Koi-Koi penalty)...")
	# Base 6 pts, no opponent koi-koi -> 6 pts
	var calc1 = KoiKoiEvaluator.calculate_final_score(6, false)
	assert(calc1.final_points == 6, "6 pts should have multiplier 1")

	# Base 7 pts -> multiplier x2 -> 14 pts
	var calc2 = KoiKoiEvaluator.calculate_final_score(7, false)
	assert(calc2.final_points == 14, "7 pts must be doubled to 14")

	# Base 5 pts, opponent called koi-koi -> multiplier x2 -> 10 pts
	var calc3 = KoiKoiEvaluator.calculate_final_score(5, true)
	assert(calc3.final_points == 10, "Winning after opponent called koi-koi must double to 10")

	# Base 8 pts, opponent called koi-koi -> multiplier x4 -> 32 pts
	var calc4 = KoiKoiEvaluator.calculate_final_score(8, true)
	assert(calc4.final_points == 32, "8 pts with opponent koi-koi must quadruple to 32")
	print("  [PASS] Score multipliers work correctly.")

func test_ai_logic() -> void:
	print("[TEST] Testing Koi-Koi AI decisions...")
	var deck: Array[Dictionary] = HanafudaCardData.get_deck_definitions()
	var hand: Array = [deck[0], deck[2]] # Month 1 Hikari, Month 1 Kasu
	var field: Array = [deck[1], deck[10]] # Month 1 Tanzaku, Month 3 Kasu

	var decision = KoiKoiAI.choose_hand_card(hand, field, [], [])
	assert(decision.card != null, "AI must choose a hand card")
	assert(decision.card["month"] == 1, "AI must choose the card that matches month 1 on field")

	# Test Koi-Koi vs Stop
	assert(not KoiKoiAI.should_call_koikoi(8, [], [], 4, "Sharp"), "AI must Stop when score >= 7")
	assert(not KoiKoiAI.should_call_koikoi(3, [], [], 1, "Sharp"), "AI must Stop when hand has 1 card left")
	print("  [PASS] AI decision logic verified.")

func test_koi_koi_scene() -> void:
	print("[TEST] Testing Koi-Koi Game Scene & Turn Interaction...")
	var scene: PackedScene = load("res://scenes/koi_koi.tscn")
	assert(scene != null, "Failed to load koi_koi.tscn")
	var game: KoiKoiGame = scene.instantiate()
	game.is_instant_mode = true
	root.add_child(game)
	await process_frame

	# Verify nodes
	assert(game.player_hand.size() == 8, "Player must have 8 cards dealt")
	assert(game.ai_hand.size() == 8, "AI must have 8 cards dealt")
	assert(game.field_cards.size() == 8, "Field must have 8 cards dealt")
	assert(game.deck_data.size() == 24, "Deck must have 24 cards remaining")

	# Verify plain #1f2326 card back on AI card
	var ai_card: HanafudaCard = game.ai_hand[0]
	assert(not ai_card.is_face_up, "AI hand card must be face down")
	assert(ai_card.back_panel.visible, "AI hand card back must be visible")
	var sb = ai_card.back_panel.get_theme_stylebox("panel") as StyleBoxFlat
	assert(sb != null and sb.bg_color == Color("#1f2326"), "Card back panel must have color #1f2326")

	# Play a player hand card
	var player_c: HanafudaCard = game.player_hand[0]
	game._on_card_clicked(player_c)
	assert(game.player_hand.size() == 7, "Player hand should have 7 cards after play")

	# Test modal visibility
	var fake_eval = {
		"has_yaku": true,
		"total_points": 5,
		"yaku_list": [{"name": "Akatan", "points": 5}]
	}
	game._show_player_koikoi_modal(fake_eval)
	assert(game.koikoi_modal.visible, "Koi-Koi modal should be visible")

	game._on_player_called_shoubu()
	assert(not game.koikoi_modal.visible, "Koi-Koi modal should close on Shoubu")
	assert(game.round_dialog.visible, "Round dialog should appear upon win")

	game.queue_free()
	await process_frame
	print("  [PASS] Koi-Koi scene and game interactions verified.")
