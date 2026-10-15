class_name PokerHandEvaluator
extends RefCounted

## Evaluates and ranks Texas Hold'em poker hands.
## Determines hand rankings (Royal Flush down to High Card),
## produces tie-breaker score vectors, and generates human-readable descriptions.

enum HandRank {
	HIGH_CARD = 0,
	ONE_PAIR = 1,
	TWO_PAIR = 2,
	THREE_OF_A_KIND = 3,
	STRAIGHT = 4,
	FLUSH = 5,
	FULL_HOUSE = 6,
	FOUR_OF_A_KIND = 7,
	STRAIGHT_FLUSH = 8,
	ROYAL_FLUSH = 9,
}

static func rank_to_string(rank: int) -> String:
	match rank:
		14, 1: return "Ace"
		13: return "King"
		12: return "Queen"
		11: return "Jack"
		10: return "10"
		_: return str(rank)

static func rank_to_plural(rank: int) -> String:
	match rank:
		14, 1: return "Aces"
		13: return "Kings"
		12: return "Queens"
		11: return "Jacks"
		6: return "Sixes"
		_: return "%ss" % rank_to_string(rank)

## Normalize rank: Aces are represented as 14 internally.
static func normalize_rank(rank: int) -> int:
	return 14 if rank == 1 else rank

## Compare two score arrays lexicographically.
## Returns 1 if score_a > score_b, -1 if score_a < score_b, 0 if equal.
static func compare_scores(score_a: Array, score_b: Array) -> int:
	var n: int = mini(score_a.size(), score_b.size())
	for i in range(n):
		var val_a = score_a[i]
		var val_b = score_b[i]
		if val_a > val_b:
			return 1
		elif val_a < val_b:
			return -1
	if score_a.size() > score_b.size():
		return 1
	elif score_a.size() < score_b.size():
		return -1
	return 0

## Evaluates an exact 5-card hand.
## Each card should be a Dictionary or Object with 'rank' (int) and 'suit' (String).
## Returns Dictionary: { "rank_type": HandRank, "score": Array, "description": String, "cards": Array }
static func evaluate_5_card_hand(cards: Array) -> Dictionary:
	assert(cards.size() == 5, "Hand must contain exactly 5 cards")
	
	# Extract and normalize
	var parsed: Array[Dictionary] = []
	for c in cards:
		var r: int = normalize_rank(c.rank if "rank" in c else c["rank"])
		var s: String = str(c.suit if "suit" in c else c["suit"]).capitalize()
		parsed.append({ "rank": r, "suit": s, "orig": c })
	
	# Sort descending by rank
	parsed.sort_custom(func(a, b): return a["rank"] > b["rank"])
	
	var ranks: Array[int] = []
	var suits: Array[String] = []
	for p in parsed:
		ranks.append(p["rank"])
		suits.append(p["suit"])
	
	# Check Flush
	var is_flush: bool = true
	for i in range(1, 5):
		if suits[i] != suits[0]:
			is_flush = false
			break
	
	# Check Straight
	var is_straight: bool = false
	var straight_high: int = 0
	
	if ranks[0] == ranks[1] + 1 and ranks[1] == ranks[2] + 1 and ranks[2] == ranks[3] + 1 and ranks[3] == ranks[4] + 1:
		is_straight = true
		straight_high = ranks[0]
	elif ranks[0] == 14 and ranks[1] == 5 and ranks[2] == 4 and ranks[3] == 3 and ranks[4] == 2:
		# Ace-low wheel (5-4-3-2-A)
		is_straight = true
		straight_high = 5
	
	# Count rank frequencies
	var freq: Dictionary = {}
	for r in ranks:
		freq[r] = freq.get(r, 0) + 1
	
	# Group by frequency then by rank descending
	# items: Array of { "rank": int, "count": int }
	var groups: Array[Dictionary] = []
	for r in freq.keys():
		groups.append({ "rank": r, "count": freq[r] })
	groups.sort_custom(func(a, b):
		if a["count"] != b["count"]:
			return a["count"] > b["count"]
		return a["rank"] > b["rank"]
	)
	
	# 1. Straight Flush / Royal Flush
	if is_flush and is_straight:
		if straight_high == 14:
			return {
				"rank_type": HandRank.ROYAL_FLUSH,
				"score": [HandRank.ROYAL_FLUSH, 14],
				"description": "Royal Flush",
				"cards": cards,
			}
		else:
			return {
				"rank_type": HandRank.STRAIGHT_FLUSH,
				"score": [HandRank.STRAIGHT_FLUSH, straight_high],
				"description": "Straight Flush, %s High" % rank_to_string(straight_high),
				"cards": cards,
			}
	
	# 2. Four of a Kind
	if groups[0]["count"] == 4:
		var four_rank: int = groups[0]["rank"]
		var kicker: int = groups[1]["rank"]
		return {
			"rank_type": HandRank.FOUR_OF_A_KIND,
			"score": [HandRank.FOUR_OF_A_KIND, four_rank, kicker],
			"description": "Four of a Kind, %s" % rank_to_plural(four_rank),
			"cards": cards,
		}
	
	# 3. Full House
	if groups[0]["count"] == 3 and groups[1]["count"] == 2:
		var three_rank: int = groups[0]["rank"]
		var pair_rank: int = groups[1]["rank"]
		return {
			"rank_type": HandRank.FULL_HOUSE,
			"score": [HandRank.FULL_HOUSE, three_rank, pair_rank],
			"description": "Full House, %s full of %s" % [rank_to_plural(three_rank), rank_to_plural(pair_rank)],
			"cards": cards,
		}
	
	# 4. Flush
	if is_flush:
		var score: Array = [HandRank.FLUSH]
		score.append_array(ranks)
		return {
			"rank_type": HandRank.FLUSH,
			"score": score,
			"description": "Flush, %s High" % rank_to_string(ranks[0]),
			"cards": cards,
		}
	
	# 5. Straight
	if is_straight:
		return {
			"rank_type": HandRank.STRAIGHT,
			"score": [HandRank.STRAIGHT, straight_high],
			"description": "Straight, %s High" % rank_to_string(straight_high),
			"cards": cards,
		}
	
	# 6. Three of a Kind
	if groups[0]["count"] == 3:
		var three_rank: int = groups[0]["rank"]
		var k1: int = groups[1]["rank"]
		var k2: int = groups[2]["rank"]
		return {
			"rank_type": HandRank.THREE_OF_A_KIND,
			"score": [HandRank.THREE_OF_A_KIND, three_rank, k1, k2],
			"description": "Three of a Kind, %s" % rank_to_plural(three_rank),
			"cards": cards,
		}
	
	# 7. Two Pair
	if groups[0]["count"] == 2 and groups[1]["count"] == 2:
		var high_pair: int = groups[0]["rank"]
		var low_pair: int = groups[1]["rank"]
		var kicker: int = groups[2]["rank"]
		return {
			"rank_type": HandRank.TWO_PAIR,
			"score": [HandRank.TWO_PAIR, high_pair, low_pair, kicker],
			"description": "Two Pair, %s and %s" % [rank_to_plural(high_pair), rank_to_plural(low_pair)],
			"cards": cards,
		}
	
	# 8. One Pair
	if groups[0]["count"] == 2:
		var pair_rank: int = groups[0]["rank"]
		var k1: int = groups[1]["rank"]
		var k2: int = groups[2]["rank"]
		var k3: int = groups[3]["rank"]
		return {
			"rank_type": HandRank.ONE_PAIR,
			"score": [HandRank.ONE_PAIR, pair_rank, k1, k2, k3],
			"description": "Pair of %s" % rank_to_plural(pair_rank),
			"cards": cards,
		}
	
	# 9. High Card
	var score: Array = [HandRank.HIGH_CARD]
	score.append_array(ranks)
	return {
		"rank_type": HandRank.HIGH_CARD,
		"score": score,
		"description": "High Card, %s" % rank_to_string(ranks[0]),
		"cards": cards,
	}

## Finds the best 5-card poker hand from any pool of cards (5 to 7 cards).
## Returns Dictionary: { "rank_type": HandRank, "score": Array, "description": String, "cards": Array }
static func evaluate_best_hand(cards: Array) -> Dictionary:
	if cards.size() < 5:
		if cards.size() == 2:
			return _describe_hole_cards(cards)
		return {
			"rank_type": HandRank.HIGH_CARD,
			"score": [HandRank.HIGH_CARD],
			"description": "Cards in play",
			"cards": cards.duplicate(),
		}
	
	if cards.size() == 5:
		return evaluate_5_card_hand(cards)
	
	# Generate 5-card combinations
	var combinations: Array[Array] = []
	_generate_combinations(cards, 5, 0, [], combinations)
	
	var best_hand: Dictionary = {}
	for comb in combinations:
		var eval_res: Dictionary = evaluate_5_card_hand(comb)
		if best_hand.is_empty() or compare_scores(eval_res["score"], best_hand["score"]) > 0:
			best_hand = eval_res
	
	return best_hand

static func _generate_combinations(arr: Array, k: int, start: int, current: Array, out_results: Array[Array]) -> void:
	if current.size() == k:
		out_results.append(current.duplicate())
		return
	for i in range(start, arr.size()):
		current.append(arr[i])
		_generate_combinations(arr, k, i + 1, current, out_results)
		current.pop_back()

static func _describe_hole_cards(cards: Array) -> Dictionary:
	var r1: int = normalize_rank(cards[0].rank if "rank" in cards[0] else cards[0]["rank"])
	var r2: int = normalize_rank(cards[1].rank if "rank" in cards[1] else cards[1]["rank"])
	var s1: String = str(cards[0].suit if "suit" in cards[0] else cards[0]["suit"]).capitalize()
	var s2: String = str(cards[1].suit if "suit" in cards[1] else cards[1]["suit"]).capitalize()
	
	var high: int = maxi(r1, r2)
	var low: int = mini(r1, r2)
	var is_suited: bool = (s1 == s2)
	
	if high == low:
		return {
			"rank_type": HandRank.ONE_PAIR,
			"score": [HandRank.ONE_PAIR, high, high],
			"description": "Pocket %s" % rank_to_plural(high),
			"cards": cards.duplicate(),
		}
	else:
		var desc: String = "%s-%s" % [rank_to_string(high), rank_to_string(low)]
		if is_suited:
			desc += " Suited"
		return {
			"rank_type": HandRank.HIGH_CARD,
			"score": [HandRank.HIGH_CARD, high, low],
			"description": desc,
			"cards": cards.duplicate(),
		}
