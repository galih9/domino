extends SceneTree

const PokerHandEvaluator = preload("res://scripts/PokerHandEvaluator.gd")

func _initialize():
	print("--- BEGINNING POKER EVALUATOR TESTS ---")
	test_royal_flush()
	test_straight_flush()
	test_four_of_a_kind()
	test_full_house()
	test_flush()
	test_straight_and_wheel()
	test_three_of_a_kind()
	test_two_pair()
	test_one_pair()
	test_high_card()
	test_7_card_selection()
	test_hand_comparison()
	print("--- ALL POKER EVALUATOR TESTS PASSED ---")
	quit(0)

func test_royal_flush():
	var cards = [
		{"suit": "Spades", "rank": 14},
		{"suit": "Spades", "rank": 13},
		{"suit": "Spades", "rank": 12},
		{"suit": "Spades", "rank": 11},
		{"suit": "Spades", "rank": 10}
	]
	var res = PokerHandEvaluator.evaluate_5_card_hand(cards)
	assert(res.rank_type == PokerHandEvaluator.HandRank.ROYAL_FLUSH, "Expected Royal Flush")
	assert(res.description == "Royal Flush")

func test_straight_flush():
	var cards = [
		{"suit": "Hearts", "rank": 9},
		{"suit": "Hearts", "rank": 8},
		{"suit": "Hearts", "rank": 7},
		{"suit": "Hearts", "rank": 6},
		{"suit": "Hearts", "rank": 5}
	]
	var res = PokerHandEvaluator.evaluate_5_card_hand(cards)
	assert(res.rank_type == PokerHandEvaluator.HandRank.STRAIGHT_FLUSH, "Expected Straight Flush")
	assert(res.score[1] == 9)

func test_four_of_a_kind():
	var cards = [
		{"suit": "Hearts", "rank": 10},
		{"suit": "Diamonds", "rank": 10},
		{"suit": "Clubs", "rank": 10},
		{"suit": "Spades", "rank": 10},
		{"suit": "Hearts", "rank": 14}
	]
	var res = PokerHandEvaluator.evaluate_5_card_hand(cards)
	assert(res.rank_type == PokerHandEvaluator.HandRank.FOUR_OF_A_KIND, "Expected Four of a Kind")
	assert(res.score[1] == 10 and res.score[2] == 14)

func test_full_house():
	var cards = [
		{"suit": "Hearts", "rank": 13},
		{"suit": "Diamonds", "rank": 13},
		{"suit": "Clubs", "rank": 13},
		{"suit": "Spades", "rank": 8},
		{"suit": "Hearts", "rank": 8}
	]
	var res = PokerHandEvaluator.evaluate_5_card_hand(cards)
	assert(res.rank_type == PokerHandEvaluator.HandRank.FULL_HOUSE, "Expected Full House")
	assert(res.score[1] == 13 and res.score[2] == 8)

func test_flush():
	var cards = [
		{"suit": "Clubs", "rank": 14},
		{"suit": "Clubs", "rank": 10},
		{"suit": "Clubs", "rank": 8},
		{"suit": "Clubs", "rank": 6},
		{"suit": "Clubs", "rank": 2}
	]
	var res = PokerHandEvaluator.evaluate_5_card_hand(cards)
	assert(res.rank_type == PokerHandEvaluator.HandRank.FLUSH, "Expected Flush")
	assert(res.score[1] == 14)

func test_straight_and_wheel():
	# Regular straight
	var cards = [
		{"suit": "Clubs", "rank": 10},
		{"suit": "Hearts", "rank": 9},
		{"suit": "Diamonds", "rank": 8},
		{"suit": "Spades", "rank": 7},
		{"suit": "Hearts", "rank": 6}
	]
	var res = PokerHandEvaluator.evaluate_5_card_hand(cards)
	assert(res.rank_type == PokerHandEvaluator.HandRank.STRAIGHT, "Expected Straight")
	assert(res.score[1] == 10)

	# Wheel straight: 5-4-3-2-A
	var wheel = [
		{"suit": "Clubs", "rank": 14}, # Ace
		{"suit": "Hearts", "rank": 5},
		{"suit": "Diamonds", "rank": 4},
		{"suit": "Spades", "rank": 3},
		{"suit": "Hearts", "rank": 2}
	]
	var res_wheel = PokerHandEvaluator.evaluate_5_card_hand(wheel)
	assert(res_wheel.rank_type == PokerHandEvaluator.HandRank.STRAIGHT, "Expected Wheel Straight")
	assert(res_wheel.score[1] == 5, "Wheel straight high card must be 5")

func test_three_of_a_kind():
	var cards = [
		{"suit": "Clubs", "rank": 7},
		{"suit": "Hearts", "rank": 7},
		{"suit": "Diamonds", "rank": 7},
		{"suit": "Spades", "rank": 12},
		{"suit": "Hearts", "rank": 2}
	]
	var res = PokerHandEvaluator.evaluate_5_card_hand(cards)
	assert(res.rank_type == PokerHandEvaluator.HandRank.THREE_OF_A_KIND, "Expected Three of a Kind")
	assert(res.score[1] == 7 and res.score[2] == 12 and res.score[3] == 2)

func test_two_pair():
	var cards = [
		{"suit": "Clubs", "rank": 14},
		{"suit": "Hearts", "rank": 14},
		{"suit": "Diamonds", "rank": 9},
		{"suit": "Spades", "rank": 9},
		{"suit": "Hearts", "rank": 4}
	]
	var res = PokerHandEvaluator.evaluate_5_card_hand(cards)
	assert(res.rank_type == PokerHandEvaluator.HandRank.TWO_PAIR, "Expected Two Pair")
	assert(res.score[1] == 14 and res.score[2] == 9 and res.score[3] == 4)

func test_one_pair():
	var cards = [
		{"suit": "Clubs", "rank": 11},
		{"suit": "Hearts", "rank": 11},
		{"suit": "Diamonds", "rank": 10},
		{"suit": "Spades", "rank": 6},
		{"suit": "Hearts", "rank": 3}
	]
	var res = PokerHandEvaluator.evaluate_5_card_hand(cards)
	assert(res.rank_type == PokerHandEvaluator.HandRank.ONE_PAIR, "Expected One Pair")
	assert(res.score[1] == 11 and res.score[2] == 10 and res.score[3] == 6 and res.score[4] == 3)

func test_high_card():
	var cards = [
		{"suit": "Clubs", "rank": 14},
		{"suit": "Hearts", "rank": 12},
		{"suit": "Diamonds", "rank": 9},
		{"suit": "Spades", "rank": 7},
		{"suit": "Hearts", "rank": 3}
	]
	var res = PokerHandEvaluator.evaluate_5_card_hand(cards)
	assert(res.rank_type == PokerHandEvaluator.HandRank.HIGH_CARD, "Expected High Card")
	assert(res.score[1] == 14 and res.score[2] == 12)

func test_7_card_selection():
	# 7 cards containing a flush and a pair
	var pool = [
		{"suit": "Diamonds", "rank": 14}, # Ace Diamonds
		{"suit": "Diamonds", "rank": 10}, # 10 Diamonds
		{"suit": "Diamonds", "rank": 8},  # 8 Diamonds
		{"suit": "Diamonds", "rank": 6},  # 6 Diamonds
		{"suit": "Diamonds", "rank": 3},  # 3 Diamonds
		{"suit": "Hearts", "rank": 14},   # Ace Hearts
		{"suit": "Spades", "rank": 14}    # Ace Spades
	]
	# Best hand should be Flush or Three of a kind?
	# Flush beats Three of a Kind!
	var res = PokerHandEvaluator.evaluate_best_hand(pool)
	assert(res.rank_type == PokerHandEvaluator.HandRank.FLUSH, "Flush beats Three of a Kind")
	assert(res.score[1] == 14)

func test_hand_comparison():
	var flush_score = [PokerHandEvaluator.HandRank.FLUSH, 14, 10, 8, 6, 3]
	var straigh_score = [PokerHandEvaluator.HandRank.STRAIGHT, 14]
	var pair_kings = [PokerHandEvaluator.HandRank.ONE_PAIR, 13, 10, 8, 4]
	var pair_aces = [PokerHandEvaluator.HandRank.ONE_PAIR, 14, 9, 6, 2]
	var pair_aces_higher_kicker = [PokerHandEvaluator.HandRank.ONE_PAIR, 14, 10, 6, 2]

	assert(PokerHandEvaluator.compare_scores(flush_score, straigh_score) == 1, "Flush should beat straight")
	assert(PokerHandEvaluator.compare_scores(straigh_score, flush_score) == -1, "Straight should lose to flush")
	assert(PokerHandEvaluator.compare_scores(pair_aces, pair_kings) == 1, "Pair of Aces should beat Pair of Kings")
	assert(PokerHandEvaluator.compare_scores(pair_aces_higher_kicker, pair_aces) == 1, "Higher kicker should win")
	assert(PokerHandEvaluator.compare_scores(pair_aces, pair_aces) == 0, "Identical scores should tie")
