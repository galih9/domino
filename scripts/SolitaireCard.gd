class_name SolitaireCard
extends Control

## Playing Card visual component for Klondike Solitaire.
## Handles suit, rank, 3D flip animation, dragging, and hover effects.

signal card_clicked(card: SolitaireCard)
signal card_double_clicked(card: SolitaireCard)
signal drag_started(card: SolitaireCard, global_pos: Vector2)
signal drag_updated(card: SolitaireCard, global_pos: Vector2)
signal drag_ended(card: SolitaireCard, global_pos: Vector2)
signal card_hovered(card: SolitaireCard, is_hovering: bool)

static var is_any_card_dragging: bool = false

@export var suit: String = "Spades" # Clubs, Diamonds, Hearts, Spades
@export var rank: int = 1 # 1 (Ace) to 13 (King)
@export var is_face_up: bool = false

var pile_type: String = "stock" # "stock", "waste", "foundation", "tableau"
var pile_index: int = 0
var base_pos: Vector2 = Vector2.ZERO

var _is_pressed: bool = false
var _is_dragging: bool = false
var _is_hovered: bool = false
var is_moving: bool = false
var _press_pos: Vector2 = Vector2.ZERO
var _last_click_time: float = 0.0

var _flip_tween: Tween = null
var _move_tween: Tween = null

@onready var shadow: TextureRect = $Shadow
@onready var front_texture: TextureRect = $FrontTexture
@onready var back_texture: TextureRect = $BackTexture
@onready var highlight_glow: Panel = $HighlightGlow

const CARD_WIDTH: float = 100.0
const CARD_HEIGHT: float = 136.0

func _ready() -> void:
	custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	size = custom_minimum_size
	pivot_offset = size * 0.5
	mouse_filter = Control.MOUSE_FILTER_STOP

	_update_textures()
	_update_face_visibility()

	if highlight_glow != null:
		highlight_glow.visible = false

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)

func setup(p_suit: String, p_rank: int, p_face_up: bool = false) -> void:
	suit = p_suit
	rank = p_rank
	is_face_up = p_face_up
	if is_node_ready():
		_update_textures()
		_update_face_visibility()

func is_red() -> bool:
	return suit == "Hearts" or suit == "Diamonds"

func is_black() -> bool:
	return suit == "Spades" or suit == "Clubs"

func get_card_color() -> String:
	return "red" if is_red() else "black"

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

func set_face_up(face_up: bool) -> void:
	is_face_up = face_up
	_update_face_visibility()

func flip_to(face_up: bool, duration: float = 0.22) -> Tween:
	if is_face_up == face_up:
		return null
	is_face_up = face_up

	if _flip_tween and _flip_tween.is_valid():
		_flip_tween.kill()

	set_highlight(false)
	var orig_scale_x: float = scale.x if scale.x > 0.0 else 1.0

	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale:x", 0.0, duration * 0.5)
	tween.tween_callback(func():
		_update_face_visibility()
		SoundManager.play_flip()
	)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale:x", orig_scale_x, duration * 0.5)
	tween.chain().tween_callback(func():
		_update_hover_state()
	)
	_flip_tween = tween
	return tween

func animate_to(target_pos: Vector2, target_rot: float = 0.0, target_scale: Vector2 = Vector2.ONE,
				duration: float = 0.22, final_z: int = -1) -> Tween:
	if _move_tween and _move_tween.is_valid():
		_move_tween.kill()

	is_moving = true
	set_highlight(false)
	base_pos = target_pos
	var tween: Tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", target_pos, duration)
	tween.tween_property(self, "rotation", target_rot, duration)
	tween.tween_property(self, "scale", target_scale, duration)

	z_index = maxi(z_index, 100)
	tween.chain().tween_callback(func():
		is_moving = false
		if final_z >= 0:
			z_index = final_z
		_update_hover_state()
	)
	_move_tween = tween
	return tween

func stop_movement() -> void:
	if _move_tween and _move_tween.is_valid():
		_move_tween.kill()
	is_moving = false

func is_card_moving() -> bool:
	if not is_moving:
		return false
	if _move_tween == null or not _move_tween.is_valid():
		is_moving = false
		return false
	return true

func set_highlight(active: bool) -> void:
	if highlight_glow != null:
		highlight_glow.visible = active

func _on_mouse_entered() -> void:
	_is_hovered = true
	_update_hover_state()
	card_hovered.emit(self, true)

func _on_mouse_exited() -> void:
	_is_hovered = false
	_update_hover_state()
	card_hovered.emit(self, false)

func _update_hover_state() -> void:
	if _is_dragging:
		set_highlight(true)
		return
	if is_card_moving() or (is_any_card_dragging and not _is_dragging):
		set_highlight(false)
		return
	set_highlight(_is_hovered)

func can_drag() -> bool:
	return is_face_up and pile_type != "stock" and not is_card_moving()

func cancel_drag() -> void:
	_is_dragging = false
	is_any_card_dragging = false
	_update_hover_state()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if _is_dragging:
			_is_dragging = false
			is_any_card_dragging = false
			drag_ended.emit(self, global_position)
		_is_pressed = false
		_is_hovered = false
		_update_hover_state()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if is_card_moving():
				accept_event()
				return
			_is_pressed = true
			_is_dragging = false
			_press_pos = event.global_position
			accept_event()
		else:
			if _is_dragging:
				_is_dragging = false
				is_any_card_dragging = false
				drag_ended.emit(self, event.global_position)
				_update_hover_state()
			elif _is_pressed:
				var current_time: float = Time.get_ticks_msec() / 1000.0
				if current_time - _last_click_time < 0.28:
					card_double_clicked.emit(self)
					_last_click_time = 0.0
				else:
					card_clicked.emit(self)
					_last_click_time = current_time
			_is_pressed = false
			accept_event()

	elif event is InputEventMouseMotion:
		if _is_pressed:
			if not _is_dragging:
				if can_drag() and event.global_position.distance_to(_press_pos) > 6.0:
					_is_dragging = true
					is_any_card_dragging = true
					set_highlight(true)
					drag_started.emit(self, event.global_position)
			if _is_dragging:
				drag_updated.emit(self, event.global_position)
			accept_event()
