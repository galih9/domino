class_name KoiKoiAI
extends RefCounted

## Strategic AI opponent for Koi-Koi Hanafuda game.
## Evaluates offensive synergy (forming Yaku) and defensive blocking (denying opponent Yaku),
## and makes intelligent risk-reward decisions for calling Koi-Koi or Stop (Shoubu).

const KoiKoiEvaluator = preload("res://scripts/KoiKoiEvaluator.gd")
const HanafudaCardData = preload("res://scripts/HanafudaCardData.gd")

static func score_card_value(card_data: Dictionary, my_captured: Array, opp_captured: Array) -> float:
	var val: float = 1.0

	var c_type = card_data.get("card_type", HanafudaCardData.CardType.KASU)
	match c_type:
		HanafudaCardData.CardType.HIKARI:
			val += 12.0
			if card_data.get("is_moon", false) or card_data.get("is_curtain", false):
				val += 6.0
			if card_data.get("is_crane", false) or card_data.get("is_phoenix", false):
				val += 4.0
		HanafudaCardData.CardType.TANE:
			val += 6.0
			if card_data.get("is_sake_cup", false):
				val += 15.0 # Sake Cup is the most versatile card in Koi-Koi
			elif card_data.get("is_boar", false) or card_data.get("is_deer", false) or card_data.get("is_butterfly", false):
				val += 8.0 # Inoshikacho components
		HanafudaCardData.CardType.TANZAKU:
			val += 4.0
			var tan = card_data.get("tanzaku_type", HanafudaCardData.TanzakuType.NONE)
			if tan == HanafudaCardData.TanzakuType.AKATAN or tan == HanafudaCardData.TanzakuType.AOTAN:
				val += 5.0
		HanafudaCardData.CardType.KASU:
			val += 1.0

	# Defensive block value: Does capturing this card deny an opponent's near-complete Yaku?
	var opp_eval = KoiKoiEvaluator.evaluate_yaku(opp_captured)
	var opp_counts = opp_eval.get("counts", {})

	# Deny Moon / Curtain if opponent has Sake Cup
	var opp_has_cup: bool = false
	var opp_has_moon: bool = false
	var opp_has_curtain: bool = false
	for oc in opp_captured:
		var od = oc if oc is Dictionary else oc.card_data
		if od.get("is_sake_cup", false): opp_has_cup = true
		if od.get("is_moon", false): opp_has_moon = true
		if od.get("is_curtain", false): opp_has_curtain = true

	if card_data.get("is_sake_cup", false) and (opp_has_moon or opp_has_curtain):
		val += 16.0
	if opp_has_cup and (card_data.get("is_moon", false) or card_data.get("is_curtain", false)):
		val += 14.0

	# Deny 5th Hikari
	if opp_counts.get("hikari", 0) >= 3 and card_data.get("card_type") == HanafudaCardData.CardType.HIKARI:
		val += 18.0

	# Deny Inoshikacho
	if card_data.get("is_boar", false) or card_data.get("is_deer", false) or card_data.get("is_butterfly", false):
		var opp_inoshika_count: int = 0
		for oc in opp_captured:
			var od = oc if oc is Dictionary else oc.card_data
			if od.get("is_boar", false) or od.get("is_deer", false) or od.get("is_butterfly", false):
				opp_inoshika_count += 1
		if opp_inoshika_count == 2:
			val += 15.0

	return val

static func choose_hand_card(hand_cards: Array, field_cards: Array, ai_captured: Array, opp_captured: Array) -> Dictionary:
	if hand_cards.is_empty():
		return {"card": null, "target_field_card": null}

	var best_score: float = -9999.0
	var best_card = null
	var best_target = null

	for hc in hand_cards:
		var h_data: Dictionary = hc if hc is Dictionary else hc.card_data
		var matches: Array = KoiKoiEvaluator.find_field_matches(h_data, field_cards)

		if not matches.is_empty():
			# This card matches something on the field!
			for fc in matches:
				var f_data: Dictionary = fc if fc is Dictionary else fc.card_data
				var score: float = score_card_value(h_data, ai_captured, opp_captured) + score_card_value(f_data, ai_captured, opp_captured) + 50.0
				if score > best_score:
					best_score = score
					best_card = hc
					best_target = fc
		else:
			# No match: discarding a card to the field
			# We want to discard the LEAST valuable card to minimize giving opponent a prize
			var discard_penalty: float = score_card_value(h_data, ai_captured, opp_captured)
			var score: float = -discard_penalty
			if score > best_score:
				best_score = score
				best_card = hc
				best_target = null

	return {
		"card": best_card,
		"target_field_card": best_target
	}

static func choose_best_field_match(matches: Array, played_card: Dictionary, ai_captured: Array, opp_captured: Array) -> Object:
	if matches.is_empty():
		return null
	if matches.size() == 1:
		return matches[0]

	var best_fc = matches[0]
	var best_val: float = -999.0
	for fc in matches:
		var f_data: Dictionary = fc if fc is Dictionary else fc.card_data
		var v = score_card_value(f_data, ai_captured, opp_captured)
		if v > best_val:
			best_val = v
			best_fc = fc
	return best_fc

static func should_call_koikoi(
	current_points: int,
	ai_captured: Array,
	opp_captured: Array,
	hand_cards_remaining: int,
	difficulty: String = "Normal"
) -> bool:
	# If points >= 7, score will double on STOP! Very strong incentive to lock it in
	if current_points >= 7:
		return false

	# If very few cards left in hand, high danger of O-nagare (0 pts) or opponent stealing
	if hand_cards_remaining <= 1:
		return false

	# Assess opponent's threat level
	var opp_threat: float = 0.0
	var opp_eval = KoiKoiEvaluator.evaluate_yaku(opp_captured)
	var opp_counts = opp_eval.get("counts", {})

	if opp_counts.get("hikari", 0) >= 3: opp_threat += 4.0
	if opp_counts.get("tane", 0) >= 4: opp_threat += 3.0
	if opp_counts.get("tanzaku", 0) >= 4: opp_threat += 3.0
	if opp_counts.get("effective_kasu", 0) >= 9: opp_threat += 3.0

	var opp_has_cup: bool = false
	var opp_has_moon: bool = false
	var opp_has_curtain: bool = false
	for oc in opp_captured:
		var od = oc if oc is Dictionary else oc.card_data
		if od.get("is_sake_cup", false): opp_has_cup = true
		if od.get("is_moon", false): opp_has_moon = true
		if od.get("is_curtain", false): opp_has_curtain = true
	if opp_has_cup and (opp_has_moon or opp_has_curtain):
		opp_threat += 5.0

	if opp_threat >= 5.0:
		# Opponent is knocking on the door of a Yaku; stop now!
		return false

	if difficulty == "Sharp":
		# Sharp AI only calls Koi-Koi if turns >= 3, points < 5, and low opponent threat
		if hand_cards_remaining >= 3 and current_points <= 4 and opp_threat <= 2.0:
			return true
		return false
	else:
		# Normal AI: moderate chance if turns >= 2 and points are low
		if hand_cards_remaining >= 2 and current_points <= 3 and opp_threat <= 3.0:
			return randf() < 0.65
		return false
