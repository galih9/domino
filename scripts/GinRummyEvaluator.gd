class_name GinRummyEvaluator
extends RefCounted

## Pure algorithmic evaluator for Gin Rummy card games.
## Provides rigorous meld detection (Sets & Runs), optimal hand partitioning
## minimizing deadwood, layoff calculations, and scoring.

# Card deadwood point values in Gin Rummy:
# Ace = 1 point
# 2 through 9 = face value (2 to 9 points)
# 10, Jack (11), Queen (12), King (13) = 10 points each
static func get_card_deadwood_value(rank: int) -> int:
	if rank <= 1:
		return 1
	elif rank >= 10:
		return 10
	return rank

## Total deadwood points for an array of cards
static func calculate_deadwood_points(cards: Array) -> int:
	var total: int = 0
	for c in cards:
		var r: int = _get_rank(c)
		total += get_card_deadwood_value(r)
	return total

## Extracts rank integer from either a card object or a Dictionary {"suit": ..., "rank": ...}
static func _get_rank(card) -> int:
	if card is Dictionary:
		return card.get("rank", 1)
	elif "rank" in card:
		return card.rank
	return 1

## Extracts suit string from either a card object or a Dictionary
static func _get_suit(card) -> String:
	if card is Dictionary:
		return card.get("suit", "Spades")
	elif "suit" in card:
		return card.suit
	return "Spades"

## Returns true if cards form a valid Set: 3 or 4 cards of identical rank and distinct suits
static func is_valid_set(cards: Array) -> bool:
	if cards.size() != 3 and cards.size() != 4:
		return false
	var target_rank: int = _get_rank(cards[0])
	var seen_suits: Dictionary = {}
	for c in cards:
		if _get_rank(c) != target_rank:
			return false
		var s: String = _get_suit(c)
		if seen_suits.has(s):
			return false
		seen_suits[s] = true
	return true

## Returns true if cards form a valid Run: 3+ cards of identical suit and consecutive ranks (Ace low)
static func is_valid_run(cards: Array) -> bool:
	if cards.size() < 3:
		return false
	var target_suit: String = _get_suit(cards[0])
	var ranks: Array[int] = []
	for c in cards:
		if _get_suit(c) != target_suit:
			return false
		ranks.append(_get_rank(c))
	ranks.sort()
	for i in range(ranks.size() - 1):
		if ranks[i + 1] != ranks[i] + 1:
			return false
	return true

## Find all candidate valid melds (sets of 3 or 4, runs of 3, 4, 5...) in a hand
static func find_all_candidate_melds(hand: Array) -> Array:
	var candidates: Array = []

	# 1. Group cards by rank to find sets
	var by_rank: Dictionary = {}
	for c in hand:
		var r: int = _get_rank(c)
		if not by_rank.has(r):
			by_rank[r] = []
		by_rank[r].append(c)

	for r in by_rank:
		var group: Array = by_rank[r]
		if group.size() == 3:
			candidates.append(group.duplicate())
		elif group.size() == 4:
			# 4-card set
			candidates.append(group.duplicate())
			# Also four 3-card combinations
			candidates.append([group[0], group[1], group[2]])
			candidates.append([group[0], group[1], group[3]])
			candidates.append([group[0], group[2], group[3]])
			candidates.append([group[1], group[2], group[3]])

	# 2. Group cards by suit to find runs
	var by_suit: Dictionary = {}
	for c in hand:
		var s: String = _get_suit(c)
		if not by_suit.has(s):
			by_suit[s] = []
		by_suit[s].append(c)

	for s in by_suit:
		var suit_cards: Array = by_suit[s]
		# Sort by rank
		suit_cards.sort_custom(func(a, b): return _get_rank(a) < _get_rank(b))
		# Remove duplicate ranks within same suit if any (standard deck won't have any)
		var unique_suit_cards: Array = []
		for c in suit_cards:
			if unique_suit_cards.is_empty() or _get_rank(unique_suit_cards.back()) != _get_rank(c):
				unique_suit_cards.append(c)

		# Find all sequences of 3 or more consecutive ranks
		var n: int = unique_suit_cards.size()
		for i in range(n):
			var seq: Array = [unique_suit_cards[i]]
			for j in range(i + 1, n):
				if _get_rank(unique_suit_cards[j]) == _get_rank(seq.back()) + 1:
					seq.append(unique_suit_cards[j])
					if seq.size() >= 3:
						candidates.append(seq.duplicate())
				else:
					break

	return candidates

## Checks if two melds share any of the same card instances/references
static func _melds_overlap(meld_a: Array, meld_b: Array) -> bool:
	for ca in meld_a:
		for cb in meld_b:
			if _cards_are_equal(ca, cb):
				return true
	return false

static func _cards_are_equal(a, b) -> bool:
	if typeof(a) == typeof(b) and a == b:
		return true
	return _get_suit(a) == _get_suit(b) and _get_rank(a) == _get_rank(b)

## Finds the optimal partition of the hand into non-overlapping melds that MINIMIZES deadwood points.
## Returns:
## {
##   "melds": Array[Array],
##   "deadwood": Array,
##   "deadwood_points": int
## }
static func find_optimal_partition(hand: Array) -> Dictionary:
	var candidates: Array = find_all_candidate_melds(hand)

	var best_melds: Array = []
	var best_deadwood: Array = hand.duplicate()
	var best_deadwood_points: int = calculate_deadwood_points(hand)

	# Recursive search across combinations of disjoint candidate melds
	# Since hands are 10 or 11 cards, maximum number of disjoint melds is 3 (3*3 = 9)
	var state := {
		"best_melds": best_melds,
		"best_deadwood": best_deadwood,
		"best_points": best_deadwood_points
	}

	_search_melds(candidates, 0, [], hand, state)

	return {
		"melds": state["best_melds"],
		"deadwood": state["best_deadwood"],
		"deadwood_points": state["best_points"]
	}

static func _search_melds(candidates: Array, start_idx: int, current_melds: Array, hand: Array, state: Dictionary) -> void:
	# Evaluate current combination
	var used_cards: Array = []
	for m in current_melds:
		for c in m:
			used_cards.append(c)

	var remaining_cards: Array = []
	for c in hand:
		var is_used: bool = false
		for uc in used_cards:
			if _cards_are_equal(c, uc):
				is_used = true
				break
		if not is_used:
			remaining_cards.append(c)

	var dw_points: int = calculate_deadwood_points(remaining_cards)
	if dw_points < state["best_points"]:
		state["best_points"] = dw_points
		state["best_melds"] = current_melds.duplicate(true)
		state["best_deadwood"] = remaining_cards.duplicate()

	# Try adding more disjoint candidate melds
	for i in range(start_idx, candidates.size()):
		var cand: Array = candidates[i]
		var can_add: bool = true
		for cm in current_melds:
			if _melds_overlap(cm, cand):
				can_add = false
				break
		if can_add:
			current_melds.append(cand)
			_search_melds(candidates, i + 1, current_melds, hand, state)
			current_melds.pop_back()

## Evaluates all 11 possible discards from an 11-card hand.
## Returns the best card to discard and details for each option.
static func evaluate_best_discard(hand_11: Array) -> Dictionary:
	var best_card = null
	var lowest_deadwood: int = 999999
	var evaluations: Array = []

	for i in range(hand_11.size()):
		var candidate_card = hand_11[i]
		var hand_10: Array = []
		for j in range(hand_11.size()):
			if j != i:
				hand_10.append(hand_11[j])

		var part: Dictionary = find_optimal_partition(hand_10)
		var dw: int = part["deadwood_points"]
		var can_knock: bool = (dw <= 10)
		var is_gin: bool = (dw == 0)

		evaluations.append({
			"card": candidate_card,
			"deadwood": dw,
			"can_knock": can_knock,
			"is_gin": is_gin,
			"melds": part["melds"],
			"deadwood_cards": part["deadwood"]
		})

		if dw < lowest_deadwood:
			lowest_deadwood = dw
			best_card = candidate_card

	return {
		"best_card": best_card,
		"lowest_deadwood": lowest_deadwood,
		"evaluations": evaluations
	}

## Calculates valid layoffs for defender's deadwood cards onto knocker's melds.
## Layoffs are NOT allowed if knocker achieved GIN (deadwood == 0).
## Returns:
## {
##   "laid_off_cards": Array, # [{ "card": card, "target_meld": Array, "meld_type": String }]
##   "remaining_deadwood": Array,
##   "deadwood_points": int
## }
static func calculate_layoffs(knocker_melds: Array, defender_deadwood: Array) -> Dictionary:
	var laid_off: Array = []
	var remaining: Array = defender_deadwood.duplicate()

	# Work on a copy of knocker melds that can grow with layoffs
	var meld_copies: Array = []
	for m in knocker_melds:
		meld_copies.append(m.duplicate())

	var changed: bool = true
	while changed:
		changed = false
		for i in range(remaining.size() - 1, -1, -1):
			var card = remaining[i]
			var card_rank: int = _get_rank(card)
			var card_suit: String = _get_suit(card)

			var layed_card: bool = false
			for meld in meld_copies:
				if is_valid_set(meld) and meld.size() == 3:
					# Can lay off 4th card of same rank
					if _get_rank(meld[0]) == card_rank:
						meld.append(card)
						laid_off.append({
							"card": card,
							"target_meld": meld,
							"meld_type": "set"
						})
						remaining.remove_at(i)
						changed = true
						layed_card = true
						break
				elif is_valid_run(meld):
					# Check if card extends the run at either end
					# Sort meld ranks
					var ranks: Array[int] = []
					for mc in meld:
						ranks.append(_get_rank(mc))
					ranks.sort()
					var min_r: int = ranks[0]
					var max_r: int = ranks.back()
					var m_suit: String = _get_suit(meld[0])

					if card_suit == m_suit:
						if card_rank == min_r - 1 and card_rank >= 1:
							meld.append(card)
							laid_off.append({
								"card": card,
								"target_meld": meld,
								"meld_type": "run"
							})
							remaining.remove_at(i)
							changed = true
							layed_card = true
							break
						elif card_rank == max_r + 1 and card_rank <= 13:
							meld.append(card)
							laid_off.append({
								"card": card,
								"target_meld": meld,
								"meld_type": "run"
							})
							remaining.remove_at(i)
							changed = true
							layed_card = true
							break
			if layed_card:
				break

	return {
		"laid_off_cards": laid_off,
		"remaining_deadwood": remaining,
		"deadwood_points": calculate_deadwood_points(remaining)
	}

## Calculates showdown result and points awarded:
## Knocker vs Defender
## Returns:
## {
##   "winner": String, # "knocker" or "defender"
##   "is_gin": bool,
##   "is_undercut": bool,
##   "knocker_deadwood": int,
##   "defender_deadwood_before": int,
##   "defender_deadwood_after": int,
##   "points_awarded": int,
##   "summary": String
## }
static func evaluate_showdown(knocker_hand_10: Array, defender_hand_10: Array) -> Dictionary:
	var knocker_part: Dictionary = find_optimal_partition(knocker_hand_10)
	var defender_part: Dictionary = find_optimal_partition(defender_hand_10)

	var knocker_dw: int = knocker_part["deadwood_points"]
	var defender_dw_before: int = defender_part["deadwood_points"]
	var is_gin: bool = (knocker_dw == 0)

	var defender_dw_after: int = defender_dw_before
	var layoffs_result: Dictionary = {}

	if not is_gin:
		layoffs_result = calculate_layoffs(knocker_part["melds"], defender_part["deadwood"])
		defender_dw_after = layoffs_result["deadwood_points"]

	if is_gin:
		# Gin: Knocker gets 25 bonus + defender's deadwood
		var pts: int = 25 + defender_dw_before
		return {
			"winner": "knocker",
			"is_gin": true,
			"is_undercut": false,
			"knocker_deadwood": 0,
			"defender_deadwood_before": defender_dw_before,
			"defender_deadwood_after": defender_dw_after,
			"points_awarded": pts,
			"layoffs": [],
			"summary": "GIN! Knocker scores 25 bonus + %d deadwood = %d pts!" % [defender_dw_before, pts]
		}
	elif knocker_dw < defender_dw_after:
		# Standard Knock victory: Knocker gets difference in deadwood
		var pts: int = defender_dw_after - knocker_dw
		return {
			"winner": "knocker",
			"is_gin": false,
			"is_undercut": false,
			"knocker_deadwood": knocker_dw,
			"defender_deadwood_before": defender_dw_before,
			"defender_deadwood_after": defender_dw_after,
			"points_awarded": pts,
			"layoffs": layoffs_result.get("laid_off_cards", []),
			"summary": "Knock! Knocker (%d dw) defeats Defender (%d dw) for %d pts!" % [knocker_dw, defender_dw_after, pts]
		}
	else:
		# Undercut: Defender has equal or less deadwood than Knocker!
		# Defender gets 25 bonus + (knocker_dw - defender_dw_after)
		var diff: int = knocker_dw - defender_dw_after
		var pts: int = 25 + diff
		return {
			"winner": "defender",
			"is_gin": false,
			"is_undercut": true,
			"knocker_deadwood": knocker_dw,
			"defender_deadwood_before": defender_dw_before,
			"defender_deadwood_after": defender_dw_after,
			"points_awarded": pts,
			"layoffs": layoffs_result.get("laid_off_cards", []),
			"summary": "UNDERCUT! Defender (%d dw) undercuts Knocker (%d dw)! Defender wins 25 bonus + %d = %d pts!" % [defender_dw_after, knocker_dw, diff, pts]
		}
