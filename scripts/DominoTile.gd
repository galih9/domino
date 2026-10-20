class_name DominoTile
extends Control

## Domino tile visual component with 3D flip, move, hover, and highlight animations.

signal tile_clicked(tile: DominoTile)
signal tile_hovered(tile: DominoTile, is_hovering: bool)

@export var top_val: int = 0
@export var bottom_val: int = 0
@export var is_face_up: bool = false
@export var is_playable: bool = false
@export var is_interactable: bool = true

var is_selected: bool = false
var owner_id: int = -1 # 0: User, 1..3: AI, -1: Table/Boneyard
var base_scale: Vector2 = Vector2.ONE
var hand_base_pos: Vector2 = Vector2.ZERO
var boneyard_base_pos: Vector2 = Vector2.ZERO

var _is_hovered: bool = false
var _move_tween: Tween = null
var _flip_tween: Tween = null
var _glow_tween: Tween = null

@onready var shadow: TextureRect = $Shadow
@onready var texture_rect: TextureRect = $TileTexture
@onready var glow_border: Panel = $HighlightGlow

const TILE_WIDTH: float = 56.0
const TILE_HEIGHT: float = 112.0

func _ready() -> void:
	custom_minimum_size = Vector2(TILE_WIDTH, TILE_HEIGHT)
	size = custom_minimum_size
	pivot_offset = size / 2.0
	mouse_filter = Control.MOUSE_FILTER_STOP

	_update_texture()
	_update_glow(false)

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)

## Setup tile numbers and initial state
func setup(v_top: int, v_bottom: int, face_up: bool = false, owner: int = -1) -> void:
	top_val = mini(v_top, v_bottom)
	bottom_val = maxi(v_top, v_bottom)
	is_face_up = face_up
	owner_id = owner
	if is_node_ready():
		_update_texture()

func pip_sum() -> int:
	return top_val + bottom_val

func is_double() -> bool:
	return top_val == bottom_val

func has_val(v: int) -> bool:
	return top_val == v or bottom_val == v

func get_other_val(v: int) -> int:
	if top_val == v:
		return bottom_val
	elif bottom_val == v:
		return top_val
	return -1

## Updates the tile texture according to face_up state and current theme
func _update_texture() -> void:
	if not is_inside_tree() or texture_rect == null:
		return
	if is_face_up:
		texture_rect.texture = ThemeManager.get_tile_texture(top_val, bottom_val)
	else:
		texture_rect.texture = ThemeManager.get_empty_texture()

	if shadow != null:
		shadow.texture = ThemeManager.get_empty_texture()

## Reloads texture if theme changed
func refresh_theme() -> void:
	_update_texture()

## Immediately sets face-up state and updates the texture without animation
func set_face_up(face_up: bool) -> void:
	is_face_up = face_up
	_update_texture()

## 3D-like flip animation (squashes scale.x, changes texture, expands back)
func flip_to(face_up: bool, duration: float = 0.32) -> void:
	if is_face_up == face_up:
		return
	is_face_up = face_up

	if _flip_tween and _flip_tween.is_valid():
		_flip_tween.kill()

	_flip_tween = create_tween()
	_flip_tween.set_trans(Tween.TRANS_QUAD)
	_flip_tween.set_ease(Tween.EASE_IN)

	# Squash to zero width
	_flip_tween.tween_property(self, "scale:x", 0.0, duration * 0.5)
	_flip_tween.tween_callback(func():
		_update_texture()
		SoundManager.play_flip()
	)

	# Expand back to target scale
	_flip_tween.set_ease(Tween.EASE_OUT)
	_flip_tween.tween_property(self, "scale:x", base_scale.x, duration * 0.5)

## Smoothly moves the tile to a global/local position with rotation and scaling
func animate_to(target_pos: Vector2, target_rot: float = 0.0, target_scale: Vector2 = Vector2.ONE,
				duration: float = 0.38, play_sound: bool = false, _arc_height: float = 24.0, final_z: int = 0) -> Tween:
	if _move_tween and _move_tween.is_valid():
		_move_tween.kill()

	base_scale = target_scale
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)

	# Position tween
	tween.tween_property(self, "position", target_pos, duration)
	# Rotation tween
	tween.tween_property(self, "rotation", target_rot, duration)
	# Scale tween
	tween.tween_property(self, "scale", target_scale, duration)

	# Elevated z-index while moving
	z_index = maxi(z_index, 50)
	tween.chain().tween_callback(func():
		z_index = final_z
		if play_sound:
			SoundManager.play_tile_place()
	)
	_move_tween = tween
	return tween

## Shuffling movement effect
func animate_shuffle(center_pos: Vector2, delay: float = 0.0, duration: float = 0.6) -> Tween:
	if _move_tween and _move_tween.is_valid():
		_move_tween.kill()

	var tween: Tween = create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)

	var angle: float = randf() * TAU
	var radius: float = randf_range(40.0, 160.0)
	var offset: Vector2 = Vector2(cos(angle), sin(angle)) * radius
	var intermediate_pos: Vector2 = center_pos + offset - Vector2(28.0, 56.0)
	var intermediate_rot: float = randf_range(-0.5, 0.5)

	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position", intermediate_pos, duration * 0.5)
	tween.parallel().tween_property(self, "rotation", intermediate_rot, duration * 0.5)

	# Second swirl
	var angle2: float = angle + randf_range(1.2, 2.8)
	var radius2: float = randf_range(30.0, 130.0)
	var final_offset: Vector2 = Vector2(cos(angle2), sin(angle2)) * radius2
	tween.tween_property(self, "position", center_pos + final_offset - Vector2(28.0, 56.0), duration * 0.5)
	tween.parallel().tween_property(self, "rotation", randf_range(-0.3, 0.3), duration * 0.5)

	_move_tween = tween
	return tween

## Set playable state (glow / dim)
func set_playable(playable: bool) -> void:
	is_playable = playable
	if not is_playable:
		is_selected = false
	_update_glow(is_playable)
	if is_playable:
		modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		# Slightly dimmed if owned by human and not playable
		if owner_id == 0:
			modulate = Color(0.75, 0.75, 0.75, 0.95)
		else:
			modulate = Color(1.0, 1.0, 1.0, 1.0)

## Set selected state (lifts higher in hand when player selects to choose arm/end)
func set_selected(selected: bool) -> void:
	is_selected = selected
	if is_selected:
		var lift_pos: Vector2 = hand_base_pos + Vector2(0, -20)
		create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).tween_property(self, "position", lift_pos, 0.15)
		z_index = 12
	else:
		if not _is_hovered:
			create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).tween_property(self, "position", hand_base_pos, 0.15)
			z_index = 0
		else:
			var lift_pos: Vector2 = hand_base_pos + Vector2(0, -16)
			create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).tween_property(self, "position", lift_pos, 0.15)
			z_index = 10

func _update_glow(active: bool) -> void:
	if glow_border == null:
		return
	glow_border.visible = active
	if _glow_tween and _glow_tween.is_valid():
		_glow_tween.kill()

	if active:
		_glow_tween = create_tween().set_loops()
		_glow_tween.tween_property(glow_border, "modulate:a", 0.4, 0.6).set_trans(Tween.TRANS_SINE)
		_glow_tween.tween_property(glow_border, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
	else:
		glow_border.modulate.a = 1.0

func _on_mouse_entered() -> void:
	if not is_interactable:
		return
	if owner_id == -1:
		_is_hovered = true
		tile_hovered.emit(self, true)
		return
	if owner_id != 0:
		return
	_is_hovered = true
	if is_playable and not is_selected:
		# Slight lift up effect in hand
		var lift_pos: Vector2 = hand_base_pos + Vector2(0, -16)
		create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).tween_property(self, "position", lift_pos, 0.15)
		z_index = 10
	tile_hovered.emit(self, true)

func _on_mouse_exited() -> void:
	if not is_interactable:
		return
	if owner_id == -1:
		_is_hovered = false
		tile_hovered.emit(self, false)
		return
	if owner_id != 0:
		return
	_is_hovered = false
	if is_playable and not is_selected:
		create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).tween_property(self, "position", hand_base_pos, 0.15)
		z_index = 0
	tile_hovered.emit(self, false)

func _on_gui_input(event: InputEvent) -> void:
	if not is_interactable:
		return
	# Allow clicks on human hand tiles (owner_id == 0) and boneyard tiles (owner_id == -1)
	if owner_id != 0 and owner_id != -1:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		tile_clicked.emit(self)
		accept_event()
