class_name KoiKoiEvaluator
extends RefCounted

## Evaluator for Koi-Koi Hanafuda game rules, matching mechanics, and Yaku combinations.

const HanafudaCardData = preload("res://scripts/HanafudaCardData.gd")

static func find_field_matches(card_data: Dictionary, field_cards: Array) -> Array:
	var matches: Array = []
	var target_month: int = card_data.get("month", -1)
	for fc in field_cards:
		var f_data: Dictionary = fc if fc is Dictionary else fc.card_data
		if f_data.get("month", -2) == target_month:
			matches.append(fc)
	return matches

## Checks if an initial deal of 8 cards has 4 of the same month (Teshi / Hand of Four).
static func check_teshi(hand: Array) -> bool:
	var month_counts: Dictionary = {}
	for c in hand:
		var c_data: Dictionary = c if c is Dictionary else c.card_data
		var m: int = c_data.get("month", 0)
		month_counts[m] = month_counts.get(m, 0) + 1
		if month_counts[m] == 4:
			return true
	return false

## Checks if an initial deal of 8 cards has four 2-card pairs (Kuttsuki / Sticky Hand).
static func check_kuttsuki(hand: Array) -> bool:
	if hand.size() != 8:
		return false
	var month_counts: Dictionary = {}
	for c in hand:
		var c_data: Dictionary = c if c is Dictionary else c.card_data
		var m: int = c_data.get("month", 0)
		month_counts[m] = month_counts.get(m, 0) + 1

	var pair_count: int = 0
	for m in month_counts.keys():
		if month_counts[m] == 2:
			pair_count += 1
		elif month_counts[m] != 0:
			return false
	return pair_count == 4

## Checks if 4 cards of the same month are on the field on deal (Kyuushuu -> field redeal).
static func check_field_four_of_a_kind(field_cards: Array) -> bool:
	var month_counts: Dictionary = {}
	for c in field_cards:
		var c_data: Dictionary = c if c is Dictionary else c.card_data
		var m: int = c_data.get("month", 0)
		month_counts[m] = month_counts.get(m, 0) + 1
		if month_counts[m] >= 4:
			return true
	return false

## Evaluates all captured cards for standard Koi-Koi Yaku combinations.
static func evaluate_yaku(captured_cards: Array, viewing_yaku_enabled: bool = true) -> Dictionary:
	var yaku_list: Array[Dictionary] = []
	var total_points: int = 0

	var hikari_cards: Array[Dictionary] = []
	var tane_cards: Array[Dictionary] = []
	var tanzaku_cards: Array[Dictionary] = []
	var kasu_cards: Array[Dictionary] = []

	var has_rainman: bool = false
	var has_moon: bool = false
	var has_curtain: bool = false
	var has_sake_cup: bool = false
	var has_boar: bool = false
	var has_deer: bool = false
	var has_butterfly: bool = false

	var akatan_count: int = 0
	var aotan_count: int = 0

	for c in captured_cards:
		var d: Dictionary = c if c is Dictionary else c.card_data
		var type = d.get("card_type", HanafudaCardData.CardType.KASU)
		match type:
			HanafudaCardData.CardType.HIKARI:
				hikari_cards.append(d)
				if d.get("is_rainman", false):
					has_rainman = true
				if d.get("is_moon", false):
					has_moon = true
				if d.get("is_curtain", false):
					has_curtain = true
			HanafudaCardData.CardType.TANE:
				tane_cards.append(d)
				if d.get("is_sake_cup", false):
					has_sake_cup = true
				if d.get("is_boar", false):
					has_boar = true
				if d.get("is_deer", false):
					has_deer = true
				if d.get("is_butterfly", false):
					has_butterfly = true
			HanafudaCardData.CardType.TANZAKU:
				tanzaku_cards.append(d)
				var tan_type = d.get("tanzaku_type", HanafudaCardData.TanzakuType.NONE)
				if tan_type == HanafudaCardData.TanzakuType.AKATAN:
					akatan_count += 1
				elif tan_type == HanafudaCardData.TanzakuType.AOTAN:
					aotan_count += 1
			HanafudaCardData.CardType.KASU:
				kasu_cards.append(d)

	# 1. Hikari (Brights) evaluation
	var num_hikari: int = hikari_cards.size()
	if num_hikari == 5:
		yaku_list.append({
			"name": "Five Brights (Goko)",
			"points": 10,
			"description": "All 5 Bright cards (Crane, Curtain, Moon, Rainman, Phoenix)",
			"cards": hikari_cards
		})
		total_points += 10
	elif num_hikari == 4:
		if has_rainman:
			yaku_list.append({
				"name": "Rainy Four Brights (Ame-Shiko)",
				"points": 7,
				"description": "4 Bright cards including the Rainman",
				"cards": hikari_cards
			})
			total_points += 7
		else:
			yaku_list.append({
				"name": "Four Brights (Shiko)",
				"points": 8,
				"description": "4 Bright cards without the Rainman",
				"cards": hikari_cards
			})
			total_points += 8
	elif num_hikari == 3:
		if not has_rainman:
			yaku_list.append({
				"name": "Three Brights (Sanko)",
				"points": 5,
				"description": "3 Bright cards without the Rainman",
				"cards": hikari_cards
			})
			total_points += 5

	# 2. Tane (Animals / Seeds) evaluation
	var has_inoshikacho: bool = has_boar and has_deer and has_butterfly
	if has_inoshikacho:
		var inoshika_pts: int = 5 + maxi(0, tane_cards.size() - 3)
		yaku_list.append({
			"name": "Boar-Deer-Butterflies (Inoshikacho)",
			"points": inoshika_pts,
			"description": "Boar, Deer, and Butterflies (+1 per additional Animal)",
			"cards": tane_cards
		})
		total_points += inoshika_pts
	elif tane_cards.size() >= 5:
		var tane_pts: int = 1 + (tane_cards.size() - 5)
		yaku_list.append({
			"name": "Animals (Tane)",
			"points": tane_pts,
			"description": "5 Animal cards (+1 per additional Animal)",
			"cards": tane_cards
		})
		total_points += tane_pts

	# 3. Tanzaku (Ribbons) evaluation
	var has_akatan: bool = (akatan_count == 3)
	var has_aotan: bool = (aotan_count == 3)

	if has_akatan and has_aotan:
		var both_pts: int = 10 + maxi(0, tanzaku_cards.size() - 6)
		yaku_list.append({
			"name": "Red & Blue Ribbons (Akatan & Aotan)",
			"points": both_pts,
			"description": "All 3 Poetry Ribbons and all 3 Blue Ribbons (+1 per extra Ribbon)",
			"cards": tanzaku_cards
		})
		total_points += both_pts
	elif has_akatan:
		var aka_pts: int = 5 + maxi(0, tanzaku_cards.size() - 3)
		yaku_list.append({
			"name": "Red Poetry Ribbons (Akatan)",
			"points": aka_pts,
			"description": "All 3 Red Poetry Ribbons (+1 per extra Ribbon)",
			"cards": tanzaku_cards
		})
		total_points += aka_pts
	elif has_aotan:
		var ao_pts: int = 5 + maxi(0, tanzaku_cards.size() - 3)
		yaku_list.append({
			"name": "Blue Ribbons (Aotan)",
			"points": ao_pts,
			"description": "All 3 Blue Ribbons (+1 per extra Ribbon)",
			"cards": tanzaku_cards
		})
		total_points += ao_pts
	elif tanzaku_cards.size() >= 5:
		var tan_pts: int = 1 + (tanzaku_cards.size() - 5)
		yaku_list.append({
			"name": "Ribbons (Tanzaku)",
			"points": tan_pts,
			"description": "5 Ribbon cards (+1 per additional Ribbon)",
			"cards": tanzaku_cards
		})
		total_points += tan_pts

	# 4. Viewing Yaku (Hanami & Tsukimi)
	if viewing_yaku_enabled and has_sake_cup:
		if has_curtain:
			yaku_list.append({
				"name": "Cherry Blossom Viewing (Hanami-de-Ippai)",
				"points": 5,
				"description": "Cherry Curtain + Sake Cup",
				"cards": []
			})
			total_points += 5
		if has_moon:
			yaku_list.append({
				"name": "Moon Viewing (Tsukimi-de-Ippai)",
				"points": 5,
				"description": "Full Moon + Sake Cup",
				"cards": []
			})
			total_points += 5

	# 5. Kasu (Chaff / Plains)
	# Standard dual-use: Sake Cup also counts as 1 Kasu card toward Kasu yaku
	var effective_kasu_count: int = kasu_cards.size() + (1 if has_sake_cup else 0)
	if effective_kasu_count >= 10:
		var kasu_pts: int = 1 + (effective_kasu_count - 10)
		yaku_list.append({
			"name": "Plains (Kasu)",
			"points": kasu_pts,
			"description": "10 Plain cards (+1 per additional Plain, Sake Cup counts)",
			"cards": kasu_cards
		})
		total_points += kasu_pts

	return {
		"yaku_list": yaku_list,
		"total_points": total_points,
		"has_yaku": not yaku_list.is_empty(),
		"counts": {
			"hikari": num_hikari,
			"tane": tane_cards.size(),
			"tanzaku": tanzaku_cards.size(),
			"kasu": kasu_cards.size(),
			"effective_kasu": effective_kasu_count
		}
	}

## Calculates score multipliers (7+ points doubling, Koi-Koi penalty doubling).
static func calculate_final_score(base_points: int, opponent_called_koikoi: bool) -> Dictionary:
	var multiplier: int = 1
	var reasons: Array[String] = []

	if base_points >= 7:
		multiplier *= 2
		reasons.append("7+ Points Bonus (x2)")

	if opponent_called_koikoi:
		multiplier *= 2
		reasons.append("Opponent Koi-Koi Counter (x2)")

	var final_pts: int = base_points * multiplier
	return {
		"base_points": base_points,
		"multiplier": multiplier,
		"final_points": final_pts,
		"reasons": reasons
	}
