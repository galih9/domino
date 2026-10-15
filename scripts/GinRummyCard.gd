class_name GinRummyCard
extends Control

const GinRummyEvaluator = preload("res://scripts/GinRummyEvaluator.gd")

## Playing Card visual component for Gin Rummy.
## Handles suit, rank, 3D flip animation, selection lift, meld glow, and hover effects.

signal card_clicked(card: GinRummyCard)
signal card_double_clicked(card: GinRummyCard)
signal card_hovered(card: GinRummyCard, is_hovering: bool)

@export var suit: String = "Spades" # Clubs, Diamonds, Hearts, Spades
@export var rank: int = 1 # 1 (Ace) to 13 (King)
@export var is_face_up: bool = false
@export var is_selected: bool = false
@export var is_melded: bool = false

var base_local_pos: Vector2 = Vector2.ZERO
var is_moving: bool = false
var _last_click_time: float = 0.0

var _flip_tween: Tween = null
var _move_tween: Tween = null
var _select_tween: Tween = null

@onready var shadow: TextureRect = $Shadow
@onready var back_texture: TextureRect = $BackTexture
@onready var front_texture: TextureRect = $FrontTexture
@onready var highlight_glow: Panel = $HighlightGlow
@onready var meld_badge: PanelContainer = $MeldBadge

const CARD_WIDTH: float = 84.0
const CARD_HEIGHT: float = 116.0
const LIFT_OFFSET: float = 18.0

func _ready() -> void:
	custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	size = custom_minimum_size
	pivot_offset = size * 0.5
	mouse_filter = Control.MOUSE_FILTER_PASS

	_update_textures()
	_update_face_visibility()
	_update_meld_indicator()

	if highlight_glow != null:
		highlight_glow.visible = false

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)

func setup(p_suit: String, p_rank: int, p_face_up: bool = false) -> void:
	suit = p_suit
	rank = p_rank
	is_face_up = p_face_up
	is_selected = false
	is_melded = false
	if is_node_ready():
		_update_textures()
		_update_face_visibility()
		_update_meld_indicator()

func get_deadwood_value() -> int:
	return GinRummyEvaluator.get_card_deadwood_value(rank)

func get_display_name() -> String:
	var r_str: String = ""
	match rank:
		1: r_str = "A"
		11: r_str = "J"
		12: r_str = "Q"
		13: r_str = "K"
		_: r_str = str(rank)
	return "%s of %s" % [r_str, suit]

func _update_textures() -> void:
	if front_texture != null:
		front_texture.texture = CardTheme.get_card_texture(suit, rank)
	if back_texture != null:
		back_texture.texture = CardTheme.get_back_texture()

func _update_face_visibility() -> void:
	if front_texture != null:
		front_texture.visible = is_face_up
	if back_texture != null:
		back_texture.visible = not is_face_up
	if meld_badge != null:
		meld_badge.visible = is_face_up and is_melded

func _update_meld_indicator() -> void:
	if meld_badge != null:
		meld_badge.visible = is_face_up and is_melded

func set_face_up(face_up: bool) -> void:
	is_face_up = face_up
	_update_face_visibility()

func set_melded(melded: bool) -> void:
	is_melded = melded
	_update_meld_indicator()

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

	if highlight_glow != null:
		highlight_glow.visible = is_selected

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

func _on_mouse_entered() -> void:
	card_hovered.emit(self, true)
	if not is_selected and highlight_glow != null:
		highlight_glow.visible = true
		highlight_glow.modulate = Color(1, 1, 1, 0.5)

func _on_mouse_exited() -> void:
	card_hovered.emit(self, false)
	if not is_selected and highlight_glow != null:
		highlight_glow.visible = false
		highlight_glow.modulate = Color(1, 1, 1, 1)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var now: float = Time.get_ticks_msec() / 1000.0
		if now - _last_click_time < 0.35:
			card_double_clicked.emit(self)
		else:
			card_clicked.emit(self)
		_last_click_time = now
