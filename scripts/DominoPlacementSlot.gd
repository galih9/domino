class_name DominoPlacementSlot
extends Node2D

## Interactive glowing domino target slot on the board.
## Displays where a tile can be placed when multiple paths/arms/ends are available.
## Provides glowing visuals, hover animations, and direct board click interaction.

signal slot_clicked(choice: String)
signal slot_hovered(choice: String, is_hovering: bool)

@export var choice: String = "" # "north", "south", "east", "west", "left", "right"
@export var slot_label: String = "" # e.g. "North", "Left"
@export var open_val: int = -1
@export var tile_size: Vector2 = Vector2(56.0, 112.0)

var is_hovered: bool = false
var pulse_time: float = 0.0
var active: bool = true

var _style_normal: StyleBoxFlat
var _style_hover: StyleBoxFlat

func _ready() -> void:
	z_index = 25 # Render above board felt and placed domino tiles
	_setup_styles()

	# Entrance animation
	modulate.a = 0.0
	scale = Vector2(0.85, 0.85)
	var tw: Tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.2)
	tw.tween_property(self, "scale", Vector2.ONE, 0.2)

func _setup_styles() -> void:
	_style_normal = StyleBoxFlat.new()
	_style_normal.set_corner_radius_all(6)
	_style_normal.set_border_width_all(2)
	_style_normal.border_color = Color(0.35, 0.90, 1.0, 0.85)
	_style_normal.bg_color = Color(0.12, 0.65, 0.95, 0.22)
	_style_normal.shadow_color = Color(0.2, 0.75, 1.0, 0.4)
	_style_normal.shadow_size = 12

	_style_hover = StyleBoxFlat.new()
	_style_hover.set_corner_radius_all(6)
	_style_hover.set_border_width_all(3)
	_style_hover.border_color = Color(1.0, 1.0, 0.6, 1.0)
	_style_hover.bg_color = Color(0.25, 0.88, 1.0, 0.42)
	_style_hover.shadow_color = Color(0.3, 0.95, 1.0, 0.7)
	_style_hover.shadow_size = 18

func _process(delta: float) -> void:
	if not active:
		return
	pulse_time += delta
	queue_redraw()

## Check whether a mouse event falls inside this slot's local bounds
func is_event_inside(event: InputEvent) -> bool:
	if not (event is InputEventMouse):
		return false
	var local_event: InputEvent = make_input_local(event)
	if local_event == null:
		return false
	var rect: Rect2 = Rect2(-tile_size * 0.5, tile_size)
	# Generous 6px margin around the domino slot so clicking borders is responsive
	return rect.grow(6.0).has_point(local_event.position)

func _input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventMouseMotion:
		var hovered_now: bool = is_event_inside(event)
		if hovered_now != is_hovered:
			is_hovered = hovered_now
			slot_hovered.emit(choice, is_hovered)
			if is_hovered:
				DisplayServer.cursor_set_shape(DisplayServer.CURSOR_POINTING_HAND)
			else:
				DisplayServer.cursor_set_shape(DisplayServer.CURSOR_ARROW)
			queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if is_event_inside(event):
			handle_click()
			get_viewport().set_input_as_handled()

func handle_click() -> void:
	if not active:
		return
	active = false
	if is_hovered:
		DisplayServer.cursor_set_shape(DisplayServer.CURSOR_ARROW)

	SoundManager.play_click()
	slot_clicked.emit(choice)

func _on_clicked() -> void:
	handle_click()

func _exit_tree() -> void:
	if is_hovered:
		DisplayServer.cursor_set_shape(DisplayServer.CURSOR_ARROW)

func _draw() -> void:
	var rect: Rect2 = Rect2(-tile_size * 0.5, tile_size)
	var pulse: float = 0.5 + 0.5 * sin(pulse_time * 4.5)

	# Update style parameters for pulsating glow
	var current_style: StyleBoxFlat = _style_hover if is_hovered else _style_normal
	if is_hovered:
		current_style.bg_color = Color(0.25, 0.88, 1.0, 0.42)
		current_style.shadow_color = Color(0.4, 0.98, 1.0, 0.75)
		current_style.shadow_size = 20
		current_style.border_color = Color(1.0, 1.0, 0.65, 1.0)
	else:
		var base_alpha: float = 0.18 + 0.12 * pulse
		current_style.bg_color = Color(0.12, 0.65, 0.95, base_alpha)
		current_style.shadow_color = Color(0.2, 0.75, 1.0, 0.35 + 0.25 * pulse)
		current_style.shadow_size = int(10 + 6 * pulse)
		current_style.border_color = Color(0.35, 0.9, 1.0, 0.75 + 0.25 * pulse)

	draw_style_box(current_style, rect)

	# Center divider line and spinner pin
	var div_color: Color = Color(1.0, 1.0, 1.0, 0.7 if is_hovered else 0.45)
	draw_line(Vector2(-tile_size.x * 0.5 + 5, 0), Vector2(tile_size.x * 0.5 - 5, 0), div_color, 1.5)
	draw_circle(Vector2.ZERO, 2.5, div_color)

	# Corner targeting accents
	var accent_color: Color = Color(1.0, 1.0, 0.7, 0.9) if is_hovered else Color(0.4, 0.95, 1.0, 0.7 + 0.3 * pulse)
	var c_len: float = 8.0
	var h_w: float = tile_size.x * 0.5 - 2.0
	var h_l: float = tile_size.y * 0.5 - 2.0

	# Top-Left corner
	draw_line(Vector2(-h_w, -h_l), Vector2(-h_w + c_len, -h_l), accent_color, 2.0)
	draw_line(Vector2(-h_w, -h_l), Vector2(-h_w, -h_l + c_len), accent_color, 2.0)
	# Top-Right corner
	draw_line(Vector2(h_w, -h_l), Vector2(h_w - c_len, -h_l), accent_color, 2.0)
	draw_line(Vector2(h_w, -h_l), Vector2(h_w, -h_l + c_len), accent_color, 2.0)
	# Bottom-Left corner
	draw_line(Vector2(-h_w, h_l), Vector2(-h_w + c_len, h_l), accent_color, 2.0)
	draw_line(Vector2(-h_w, h_l), Vector2(-h_w, h_l - c_len), accent_color, 2.0)
	# Bottom-Right corner
	draw_line(Vector2(h_w, h_l), Vector2(h_w - c_len, h_l), accent_color, 2.0)
	draw_line(Vector2(h_w, h_l), Vector2(h_w, h_l - c_len), accent_color, 2.0)

	# Draw label text upright (canceling slot rotation so text is always horizontal and easy to read)
	draw_set_transform(Vector2.ZERO, -rotation, Vector2.ONE)

	var font: Font = ThemeDB.fallback_font
	var font_size: int = 11
	var label_text: String = slot_label.to_upper()
	if open_val >= 0:
		label_text += " (%d)" % open_val

	var text_w: float = font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x
	var text_pos: Vector2 = Vector2(-text_w * 0.5, 4.0)
	var text_color: Color = Color(1.0, 1.0, 1.0, 0.95 if is_hovered else 0.85)
	draw_string(font, text_pos, label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, text_color)

	# Reset draw transform
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
