class_name ThemeManager
extends RefCounted

## Manages tile textures and visual themes for dominoes.
## Supported themes: Light (default), Dark, Gingerbread, Hearts, Stars.

const THEMES: Array[String] = ["Light", "Dark", "Gingerbread", "Hearts", "Stars"]
const DEFAULT_THEME: String = "Light"

static var current_theme: String = DEFAULT_THEME
static var _texture_cache: Dictionary = {}

static func set_theme(theme_name: String) -> void:
	if theme_name in THEMES:
		current_theme = theme_name
		_texture_cache.clear()
	else:
		push_warning("Unknown theme: %s. Using default." % theme_name)
		current_theme = DEFAULT_THEME

static func get_theme() -> String:
	return current_theme

## Returns the texture for a domino tile with pips a and b.
static func get_tile_texture(a: int, b: int, theme: String = "") -> Texture2D:
	var th: String = theme if theme != "" else current_theme
	var min_val: int = mini(a, b)
	var max_val: int = maxi(a, b)
	var cache_key: String = "%s_%d_%d" % [th, min_val, max_val]

	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key]

	var path: String = "res://assets/%s/tile_%d_%d.png" % [th, min_val, max_val]
	if ResourceLoader.exists(path):
		var tex: Texture2D = load(path)
		_texture_cache[cache_key] = tex
		return tex
	else:
		push_error("Tile texture not found: %s" % path)
		return null

## Returns the empty tile texture (used for the back of the card).
static func get_empty_texture(theme: String = "") -> Texture2D:
	var th: String = theme if theme != "" else current_theme
	var cache_key: String = "%s_empty" % th

	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key]

	var path: String = "res://assets/%s/tile_empty.png" % th
	if ResourceLoader.exists(path):
		var tex: Texture2D = load(path)
		_texture_cache[cache_key] = tex
		return tex
	else:
		push_error("Empty tile texture not found: %s" % path)
		return null
