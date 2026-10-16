class_name PokerCard
extends Control

## Playing Card visual component for Texas Hold'em Poker.
## Handles suit, rank, 3D flip animation, dealing movement, glowing highlights, and dimming.

signal card_clicked(card: PokerCard)

@export var suit: String = "Spades" # Clubs, Diamonds, Hearts, Spades
@export var rank: int = 14 # 2 to 14 (14 = Ace)
@export var is_face_up: bool = false

var is_moving: bool = false
var _flip_tween: Tween = null
var _move_tween: Tween = null

@onready var shadow: TextureRect = $Shadow
@onready var front_texture: TextureRect = $FrontTexture
@onready var back_texture: TextureRect = $BackTexture
@onready var highlight_glow: Panel = $HighlightGlow

const CARD_WIDTH: float = 84.0
const CARD_HEIGHT: float = 116.0

func _ready() -> void:
	custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	size = custom_minimum_size
	pivot_offset = size * 0.5
	mouse_filter = Control.MOUSE_FILTER_PASS

	_update_textures()
	_update_face_visibility()

	if highlight_glow != null:
		highlight_glow.visible = false

	gui_input.connect(_on_gui_input)

func setup(p_suit: String, p_rank: int, p_face_up: bool = false) -> void:
	suit = p_suit
	rank = 14 if p_rank == 1 else p_rank
	is_face_up = p_face_up
	if is_node_ready():
		_update_textures()
		_update_face_visibility()

func is_red() -> bool:
	return suit == "Hearts" or suit == "Diamonds"

func is_black() -> bool:
	return suit == "Spades" or suit == "Clubs"

func get_display_name() -> String:
	var r_str: String = ""
	match rank:
		14, 1: r_str = "A"
		11: r_str = "J"
		12: r_str = "Q"
		13: r_str = "K"
		_: r_str = str(rank)
	return "%s of %s" % [r_str, suit]

func _update_textures() -> void:
	# CardTheme uses 1 for Ace
	var theme_rank: int = 1 if rank == 14 else rank
	if front_texture != null:
		front_texture.texture = CardTheme.get_card_texture(suit, theme_rank)
	if back_texture != null:
		back_texture.texture = CardTheme.get_back_texture()

func _update_face_visibility() -> void:
	if front_texture != null:
		front_texture.visible = is_face_up
	if back_texture != null:
		back_texture.visible = not is_face_up

func set_face_up(face_up: bool) -> void:
	is_face_up = face_up
	_update_face_visibility()

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
		SoundManager.play_flip()
	)
	_flip_tween.set_ease(Tween.EASE_OUT)
	_flip_tween.tween_property(self, "scale:x", 1.0, duration * 0.5)

func move_to(target_pos: Vector2, duration: float = 0.25, trans = Tween.TRANS_QUAD) -> void:
	if _move_tween != null and _move_tween.is_valid():
		_move_tween.kill()

	is_moving = true
	_move_tween = create_tween()
	_move_tween.set_trans(trans).set_ease(Tween.EASE_OUT)
	_move_tween.tween_property(self, "position", target_pos, duration)
	_move_tween.tween_callback(func():
		is_moving = false
	)

func set_highlight(active: bool) -> void:
	if highlight_glow != null:
		highlight_glow.visible = active
	if active:
		modulate = Color(1.0, 1.0, 1.0, 1.0)

func set_dim(dim: bool) -> void:
	var target_alpha: float = 0.45 if dim else 1.0
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", target_alpha, 0.18)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		card_clicked.emit(self)
