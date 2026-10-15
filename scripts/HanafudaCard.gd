class_name HanafudaCard
extends Control

const HanafudaCardData = preload("res://scripts/HanafudaCardData.gd")

## Playing Card visual component for Hanafuda (Koi-Koi).
## Features authentic proportions, 3D flip animation, selection lift,
## plain #1f2326 card back, field match glow, and interactive hover effects.

signal card_clicked(card: HanafudaCard)
signal card_hovered(card: HanafudaCard, is_hovering: bool)

const CARD_WIDTH: float = 66.0
const CARD_HEIGHT: float = 108.0
const LIFT_OFFSET: float = 14.0
const BACK_COLOR: Color = Color("#1f2326")

@export var is_face_up: bool = false
@export var is_selected: bool = false
@export var is_matching_highlight: bool = false

var card_data: Dictionary = {}
var base_local_pos: Vector2 = Vector2.ZERO
var is_moving: bool = false

var _flip_tween: Tween = null
var _move_tween: Tween = null
var _select_tween: Tween = null
var _pulse_tween: Tween = null

@onready var shadow: Control = $Shadow
@onready var back_panel: Panel = $BackPanel
@onready var back_texture: TextureRect = $BackTexture
@onready var front_texture: TextureRect = $FrontTexture
@onready var selection_glow: Panel = $SelectionGlow
@onready var match_glow: Panel = $MatchGlow
@onready var month_badge: PanelContainer = $MonthBadge
@onready var month_label: Label = $MonthBadge/Label

func _ready() -> void:
	custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	size = custom_minimum_size
	pivot_offset = size * 0.5
	mouse_filter = Control.MOUSE_FILTER_PASS

	_setup_back_style()
	_update_textures()
	_update_face_visibility()
	_update_glows()

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)

func setup(data: Dictionary, p_face_up: bool = false) -> void:
	card_data = data
	is_face_up = p_face_up
	is_selected = false
	is_matching_highlight = false
	if is_node_ready():
		_setup_back_style()
		_update_textures()
		_update_face_visibility()
		_update_glows()

func _setup_back_style() -> void:
	if back_panel != null:
		var sb: StyleBoxFlat = StyleBoxFlat.new()
		sb.bg_color = BACK_COLOR
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
		sb.border_color = Color(0.2, 0.23, 0.26, 0.9)
		sb.corner_radius_top_left = 5
		sb.corner_radius_top_right = 5
		sb.corner_radius_bottom_right = 5
		sb.corner_radius_bottom_left = 5
		back_panel.add_theme_stylebox_override("panel", sb)

func _update_textures() -> void:
	var path: String = card_data.get("texture_path", "")
	if front_texture != null and not path.is_empty() and ResourceLoader.exists(path):
		front_texture.texture = load(path)
	if back_texture != null and ResourceLoader.exists(HanafudaCardData.CARD_BACK_PATH):
		back_texture.texture = load(HanafudaCardData.CARD_BACK_PATH)

	if month_label != null:
		var m: int = card_data.get("month", 0)
		month_label.text = str(m) if m > 0 else ""

func _update_face_visibility() -> void:
	if front_texture != null:
		front_texture.visible = is_face_up
	if back_panel != null:
		back_panel.visible = not is_face_up
	if back_texture != null:
		back_texture.visible = not is_face_up
	if month_badge != null:
		month_badge.visible = is_face_up

func _update_glows() -> void:
	if selection_glow != null:
		selection_glow.visible = is_selected
	if match_glow != null:
		match_glow.visible = is_matching_highlight

func set_face_up(face_up: bool) -> void:
	is_face_up = face_up
	_update_face_visibility()

func set_selected(selected: bool, animate: bool = true) -> void:
	if is_selected == selected:
		return
	is_selected = selected

	var target_y = base_local_pos.y - (LIFT_OFFSET if is_selected else 0.0)

	if _select_tween != null and _select_tween.is_valid():
		_select_tween.kill()

	if animate:
		_select_tween = create_tween()
		_select_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_select_tween.tween_property(self, "position:y", target_y, 0.14)
	else:
		position.y = target_y

	_update_glows()

func set_matching_highlight(highlight: bool) -> void:
	if is_matching_highlight == highlight:
		return
	is_matching_highlight = highlight

	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()

	if match_glow != null:
		match_glow.visible = is_matching_highlight
		if is_matching_highlight:
			_pulse_tween = create_tween().set_loops()
			_pulse_tween.tween_property(match_glow, "modulate:a", 1.0, 0.45).set_trans(Tween.TRANS_SINE)
			_pulse_tween.tween_property(match_glow, "modulate:a", 0.4, 0.45).set_trans(Tween.TRANS_SINE)
		else:
			match_glow.modulate.a = 1.0

func flip(face_up: bool, duration: float = 0.22) -> void:
	if is_face_up == face_up:
		return
	if _flip_tween != null and _flip_tween.is_valid():
		_flip_tween.kill()

	_flip_tween = create_tween()
	_flip_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_flip_tween.tween_property(self, "scale:x", 0.0, duration * 0.5)
	_flip_tween.tween_callback(func():
		is_face_up = face_up
		_update_face_visibility()
	)
	_flip_tween.set_ease(Tween.EASE_OUT)
	_flip_tween.tween_property(self, "scale:x", 1.0, duration * 0.5)

func move_to(target_pos: Vector2, duration: float = 0.25, trans = Tween.TRANS_QUAD) -> void:
	if _move_tween != null and _move_tween.is_valid():
		_move_tween.kill()

	is_moving = true
	base_local_pos = target_pos
	var final_y = target_pos.y - (LIFT_OFFSET if is_selected else 0.0)
	var final_pos = Vector2(target_pos.x, final_y)

	_move_tween = create_tween()
	_move_tween.set_trans(trans).set_ease(Tween.EASE_OUT)
	_move_tween.tween_property(self, "position", final_pos, duration)
	_move_tween.tween_callback(func():
		is_moving = false
	)

func get_display_name() -> String:
	return card_data.get("name", "Hanafuda Card")

func get_month() -> int:
	return card_data.get("month", 0)

func get_card_type() -> int:
	return card_data.get("card_type", HanafudaCardData.CardType.KASU)

func _on_mouse_entered() -> void:
	card_hovered.emit(self, true)
	if not is_selected and selection_glow != null:
		selection_glow.visible = true
		selection_glow.modulate = Color(1, 1, 1, 0.45)

func _on_mouse_exited() -> void:
	card_hovered.emit(self, false)
	if not is_selected and selection_glow != null:
		selection_glow.visible = false
		selection_glow.modulate = Color(1, 1, 1, 1)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		card_clicked.emit(self)
