class_name CardTheme
extends RefCounted

## Manages texture loading and caching for poker playing cards.

static var current_back: String = "cardBack_blue1.png"
static var _texture_cache: Dictionary = {}

static func set_card_back(back_name: String) -> void:
	current_back = back_name
	_texture_cache.erase("back")

static func get_card_texture(suit: String, rank: int) -> Texture2D:
	var rank_str: String = ""
	match rank:
		1: rank_str = "A"
		11: rank_str = "J"
		12: rank_str = "Q"
		13: rank_str = "K"
		_: rank_str = str(rank)

	var cache_key: String = "%s_%s" % [suit, rank_str]
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key]

	var path: String = "res://assets/Cards/card%s%s.png" % [suit, rank_str]
	if ResourceLoader.exists(path):
		var tex: Texture2D = load(path)
		_texture_cache[cache_key] = tex
		return tex
	push_error("Card texture not found: %s" % path)
	return null

static func get_back_texture() -> Texture2D:
	if _texture_cache.has("back"):
		return _texture_cache["back"]

	var path: String = "res://assets/Cards/%s" % current_back
	if ResourceLoader.exists(path):
		var tex: Texture2D = load(path)
		_texture_cache["back"] = tex
		return tex

	var fallback := "res://assets/Cards/cardBack_blue1.png"
	var tex: Texture2D = load(fallback)
	_texture_cache["back"] = tex
	return tex
