class_name HanafudaCardData
extends RefCounted

## Data definitions and lookup methods for standard 48 Hanafuda cards.

enum CardType {
	HIKARI,   # Bright (20 points in traditional scoring)
	TANE,     # Animal / Seed (10 points)
	TANZAKU,  # Ribbon / Scroll (5 points)
	KASU      # Chaff / Plain (1 point)
}

enum TanzakuType {
	NONE,
	AKATAN,   # Red poetry ribbons with calligraphy (Jan, Feb, Mar)
	AOTAN,    # Blue ribbons (Jun, Sep, Oct)
	PLAIN     # Red ribbons without writing (Apr, May, Jul, Nov)
}

const MONTH_NAMES: Array[String] = [
	"",
	"January", "February", "March", "April",
	"May", "June", "July", "August",
	"September", "October", "November", "December"
]

const FLOWER_NAMES: Array[String] = [
	"",
	"Pine (Matsu)", "Plum Blossom (Ume)", "Cherry Blossom (Sakura)", "Wisteria (Fuji)",
	"Iris (Ayame)", "Peony (Botan)", "Bush Clover (Hagi)", "Susuki Grass (Susuki)",
	"Chrysanthemum (Kiku)", "Maple (Momiji)", "Willow (Yanagi)", "Paulownia (Kiri)"
]

const CARD_BACK_COLOR: Color = Color("#1f2326")
const CARD_BACK_PATH: String = "res://assets/Hanafuda/Hanafuda_Back.svg"

static var _cached_deck: Array[Dictionary] = []

static func get_deck_definitions() -> Array[Dictionary]:
	if not _cached_deck.is_empty():
		return _cached_deck

	var cards: Array[Dictionary] = [
		# Month 1 - January: Pine
		_make_card(1, CardType.HIKARI, "Crane with Pine", "Hanafuda_January_Hikari_Alt.svg", TanzakuType.NONE, {"is_crane": true}),
		_make_card(1, CardType.TANZAKU, "Pine Poetry Ribbon", "Hanafuda_January_Tanzaku_Alt.svg", TanzakuType.AKATAN),
		_make_card(1, CardType.KASU, "Pine Kasu 1", "Hanafuda_January_Kasu_1_Alt.svg"),
		_make_card(1, CardType.KASU, "Pine Kasu 2", "Hanafuda_January_Kasu_2_Alt.svg"),

		# Month 2 - February: Plum Blossom
		_make_card(2, CardType.TANE, "Bush Warbler in Plum", "Hanafuda_February_Tane_Alt.svg", TanzakuType.NONE, {"is_warbler": true}),
		_make_card(2, CardType.TANZAKU, "Plum Poetry Ribbon", "Hanafuda_February_Tanzaku_Alt.svg", TanzakuType.AKATAN),
		_make_card(2, CardType.KASU, "Plum Kasu 1", "Hanafuda_February_Kasu_1_Alt.svg"),
		_make_card(2, CardType.KASU, "Plum Kasu 2", "Hanafuda_February_Kasu_2_Alt.svg"),

		# Month 3 - March: Cherry Blossom
		_make_card(3, CardType.HIKARI, "Cherry Curtain", "Hanafuda_March_Hikari_Alt.svg", TanzakuType.NONE, {"is_curtain": true}),
		_make_card(3, CardType.TANZAKU, "Cherry Poetry Ribbon", "Hanafuda_March_Tanzaku_Alt.svg", TanzakuType.AKATAN),
		_make_card(3, CardType.KASU, "Cherry Kasu 1", "Hanafuda_March_Kasu_1_Alt.svg"),
		_make_card(3, CardType.KASU, "Cherry Kasu 2", "Hanafuda_March_Kasu_2_Alt.svg"),

		# Month 4 - April: Wisteria
		_make_card(4, CardType.TANE, "Cuckoo in Wisteria", "Hanafuda_April_Tane_Alt.svg", TanzakuType.NONE, {"is_cuckoo": true}),
		_make_card(4, CardType.TANZAKU, "Wisteria Red Ribbon", "Hanafuda_April_Tanzaku_Alt.svg", TanzakuType.PLAIN),
		_make_card(4, CardType.KASU, "Wisteria Kasu 1", "Hanafuda_April_Kasu_1_Alt.svg"),
		_make_card(4, CardType.KASU, "Wisteria Kasu 2", "Hanafuda_April_Kasu_2_Alt.svg"),

		# Month 5 - May: Iris
		_make_card(5, CardType.TANE, "Iris with Eight-Plank Bridge", "Hanafuda_May_Tane_Alt.svg", TanzakuType.NONE, {"is_bridge": true}),
		_make_card(5, CardType.TANZAKU, "Iris Red Ribbon", "Hanafuda_May_Tanzaku_Alt.svg", TanzakuType.PLAIN),
		_make_card(5, CardType.KASU, "Iris Kasu 1", "Hanafuda_May_Kasu_1_Alt.svg"),
		_make_card(5, CardType.KASU, "Iris Kasu 2", "Hanafuda_May_Kasu_2_Alt.svg"),

		# Month 6 - June: Peony
		_make_card(6, CardType.TANE, "Butterflies in Peony", "Hanafuda_June_Tane_Alt.svg", TanzakuType.NONE, {"is_butterfly": true}),
		_make_card(6, CardType.TANZAKU, "Peony Blue Ribbon", "Hanafuda_June_Tanzaku_Alt.svg", TanzakuType.AOTAN),
		_make_card(6, CardType.KASU, "Peony Kasu 1", "Hanafuda_June_Kasu_1_Alt.svg"),
		_make_card(6, CardType.KASU, "Peony Kasu 2", "Hanafuda_June_Kasu_2_Alt.svg"),

		# Month 7 - July: Bush Clover
		_make_card(7, CardType.TANE, "Boar in Bush Clover", "Hanafuda_July_Tane_Alt.svg", TanzakuType.NONE, {"is_boar": true}),
		_make_card(7, CardType.TANZAKU, "Bush Clover Red Ribbon", "Hanafuda_July_Tanzaku_Alt.svg", TanzakuType.PLAIN),
		_make_card(7, CardType.KASU, "Bush Clover Kasu 1", "Hanafuda_July_Kasu_1_Alt.svg"),
		_make_card(7, CardType.KASU, "Bush Clover Kasu 2", "Hanafuda_July_Kasu_2_Alt.svg"),

		# Month 8 - August: Susuki Grass
		_make_card(8, CardType.HIKARI, "Full Moon over Grass", "Hanafuda_August_Hikari_Alt.svg", TanzakuType.NONE, {"is_moon": true}),
		_make_card(8, CardType.TANE, "Geese flying over Grass", "Hanafuda_August_Tane_Alt.svg", TanzakuType.NONE, {"is_geese": true}),
		_make_card(8, CardType.KASU, "Susuki Kasu 1", "Hanafuda_August_Kasu_1_Alt.svg"),
		_make_card(8, CardType.KASU, "Susuki Kasu 2", "Hanafuda_August_Kasu_2_Alt.svg"),

		# Month 9 - September: Chrysanthemum
		_make_card(9, CardType.TANE, "Sake Cup in Chrysanthemum", "Hanafuda_September_Tane_Alt.svg", TanzakuType.NONE, {"is_sake_cup": true}),
		_make_card(9, CardType.TANZAKU, "Chrysanthemum Blue Ribbon", "Hanafuda_September_Tanzaku_Alt.svg", TanzakuType.AOTAN),
		_make_card(9, CardType.KASU, "Chrysanthemum Kasu 1", "Hanafuda_September_Kasu_1_Alt.svg"),
		_make_card(9, CardType.KASU, "Chrysanthemum Kasu 2", "Hanafuda_September_Kasu_2_Alt.svg"),

		# Month 10 - October: Maple
		_make_card(10, CardType.TANE, "Deer under Maple", "Hanafuda_October_Tane_Alt.svg", TanzakuType.NONE, {"is_deer": true}),
		_make_card(10, CardType.TANZAKU, "Maple Blue Ribbon", "Hanafuda_October_Tanzaku_Alt.svg", TanzakuType.AOTAN),
		_make_card(10, CardType.KASU, "Maple Kasu 1", "Hanafuda_October_Kasu_1_Alt.svg"),
		_make_card(10, CardType.KASU, "Maple Kasu 2", "Hanafuda_October_Kasu_2_Alt.svg"),

		# Month 11 - November: Willow
		_make_card(11, CardType.HIKARI, "Rainman (Ono no Michikaze)", "Hanafuda_November_Hikari_Alt.svg", TanzakuType.NONE, {"is_rainman": true}),
		_make_card(11, CardType.TANE, "Swallow in Willow", "Hanafuda_November_Tane_Alt.svg", TanzakuType.NONE, {"is_swallow": true}),
		_make_card(11, CardType.TANZAKU, "Willow Red Ribbon", "Hanafuda_November_Tanzaku_Alt.svg", TanzakuType.PLAIN),
		_make_card(11, CardType.KASU, "Willow Lightning Kasu", "Hanafuda_November_Kasu_Alt.svg"),

		# Month 12 - December: Paulownia
		_make_card(12, CardType.HIKARI, "Chinese Phoenix in Paulownia", "Hanafuda_December_Hikari_Alt.svg", TanzakuType.NONE, {"is_phoenix": true}),
		_make_card(12, CardType.KASU, "Paulownia Kasu 1", "Hanafuda_December_Kasu_1_Alt.svg"),
		_make_card(12, CardType.KASU, "Paulownia Kasu 2", "Hanafuda_December_Kasu_2_Alt.svg"),
		_make_card(12, CardType.KASU, "Paulownia Kasu 3", "Hanafuda_December_Kasu_3_Alt.svg")
	]

	# Assign unique card IDs (0 to 47)
	for i in range(cards.size()):
		cards[i]["id"] = i

	_cached_deck = cards
	return _cached_deck

static func _make_card(
	month: int,
	type: CardType,
	display_name: String,
	file_name: String,
	tanzaku: TanzakuType = TanzakuType.NONE,
	special_tags: Dictionary = {}
) -> Dictionary:
	var type_str: String = ""
	match type:
		CardType.HIKARI: type_str = "Hikari"
		CardType.TANE: type_str = "Tane"
		CardType.TANZAKU: type_str = "Tanzaku"
		CardType.KASU: type_str = "Kasu"

	var data: Dictionary = {
		"id": -1,
		"month": month,
		"month_name": MONTH_NAMES[month],
		"flower_name": FLOWER_NAMES[month],
		"card_type": type,
		"card_type_name": type_str,
		"name": display_name,
		"file_name": file_name,
		"texture_path": "res://assets/Hanafuda/" + file_name,
		"tanzaku_type": tanzaku,
		"is_hikari": type == CardType.HIKARI,
		"is_tane": type == CardType.TANE,
		"is_tanzaku": type == CardType.TANZAKU,
		"is_kasu": type == CardType.KASU,
		"is_sake_cup": special_tags.get("is_sake_cup", false),
		"is_rainman": special_tags.get("is_rainman", false),
		"is_moon": special_tags.get("is_moon", false),
		"is_curtain": special_tags.get("is_curtain", false),
		"is_crane": special_tags.get("is_crane", false),
		"is_phoenix": special_tags.get("is_phoenix", false),
		"is_boar": special_tags.get("is_boar", false),
		"is_deer": special_tags.get("is_deer", false),
		"is_butterfly": special_tags.get("is_butterfly", false)
	}
	return data

static func create_shuffled_deck() -> Array[Dictionary]:
	var deck: Array[Dictionary] = get_deck_definitions().duplicate(true)
	deck.shuffle()
	return deck
