class_name SoundManager
extends Node

## Audio manager for all Domino & Card game modes.
## Plays sound effects loaded from res://assets/Sfx/ with pitch variation and pooling.
## Safe to call statically (e.g. SoundManager.play_card_place()) or via instance.

static var instance: SoundManager = null

const SFX_CARD_PLACE: Array[AudioStream] = [
	preload("res://assets/Sfx/cardPlace1.ogg"),
	preload("res://assets/Sfx/cardPlace2.ogg"),
	preload("res://assets/Sfx/cardPlace3.ogg")
]

const SFX_CARD_SLIDE: Array[AudioStream] = [
	preload("res://assets/Sfx/cardSlide1.ogg"),
	preload("res://assets/Sfx/cardSlide2.ogg"),
	preload("res://assets/Sfx/cardSlide3.ogg")
]

const SFX_CHIPS: Array[AudioStream] = [
	preload("res://assets/Sfx/chipsCollide1.ogg"),
	preload("res://assets/Sfx/chipsCollide2.ogg"),
	preload("res://assets/Sfx/chipsCollide3.ogg")
]

const SFX_SHUFFLE: Array[AudioStream] = [
	preload("res://assets/Sfx/diceShuffle1.ogg")
]

const SFX_DICE_THROW: Array[AudioStream] = [
	preload("res://assets/Sfx/diceThrow1.ogg"),
	preload("res://assets/Sfx/diceThrow2.ogg")
]

var _player_pool: Array[AudioStreamPlayer] = []
var _pool_size: int = 16
var _pool_index: int = 0

func _enter_tree() -> void:
	if instance == null or not is_instance_valid(instance):
		instance = self

func _ready() -> void:
	if _player_pool.is_empty():
		_init_audio_pool()

func _init_audio_pool() -> void:
	for i in range(_pool_size):
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_player_pool.append(player)

func _play_stream(stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if stream == null:
		return
	if _player_pool.is_empty():
		_init_audio_pool()
	if _player_pool.is_empty():
		return

	var player: AudioStreamPlayer = _player_pool[_pool_index]
	_pool_index = (_pool_index + 1) % _pool_size
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()

func _play_random(streams: Array[AudioStream], volume_db: float = 0.0, min_pitch: float = 0.95, max_pitch: float = 1.05) -> void:
	if streams.is_empty():
		return
	var stream: AudioStream = streams[randi() % streams.size()]
	_play_stream(stream, volume_db, randf_range(min_pitch, max_pitch))

# ---------------------------------------------------------
# Static instance accessor
# ---------------------------------------------------------
static func _ensure_instance() -> SoundManager:
	if instance != null and is_instance_valid(instance) and instance.is_inside_tree():
		return instance
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		var existing: Node = tree.root.get_node_or_null("SoundManager")
		if existing is SoundManager and is_instance_valid(existing):
			instance = existing
			return instance
		var new_mgr := SoundManager.new()
		new_mgr.name = "SoundManager"
		tree.root.add_child(new_mgr)
		instance = new_mgr
		return instance
	return null

# ---------------------------------------------------------
# Core Playback Methods (Callable statically or via instance)
# ---------------------------------------------------------
static func play_card_place(volume_db: float = -1.0) -> void:
	var mgr := _ensure_instance()
	if mgr: mgr._play_random(SFX_CARD_PLACE, volume_db, 0.96, 1.04)

static func play_card_slide(volume_db: float = -2.0) -> void:
	var mgr := _ensure_instance()
	if mgr: mgr._play_random(SFX_CARD_SLIDE, volume_db, 0.95, 1.05)

static func play_tile_place(volume_db: float = 0.0) -> void:
	var mgr := _ensure_instance()
	if mgr: mgr._play_random(SFX_DICE_THROW, volume_db, 0.94, 1.06)

static func play_chips(volume_db: float = -2.0) -> void:
	var mgr := _ensure_instance()
	if mgr: mgr._play_random(SFX_CHIPS, volume_db, 0.95, 1.05)

static func play_shuffle(volume_db: float = -1.0) -> void:
	var mgr := _ensure_instance()
	if mgr: mgr._play_random(SFX_SHUFFLE, volume_db, 0.98, 1.02)

static func play_dice_throw(volume_db: float = 0.0) -> void:
	var mgr := _ensure_instance()
	if mgr: mgr._play_random(SFX_DICE_THROW, volume_db, 0.95, 1.05)

static func play_knock(volume_db: float = 0.0) -> void:
	var mgr := _ensure_instance()
	if mgr: mgr._play_random(SFX_DICE_THROW, volume_db, 0.84, 0.92)

static func play_deal(volume_db: float = -2.0) -> void:
	play_card_slide(volume_db)

static func play_draw(volume_db: float = -2.0) -> void:
	play_card_slide(volume_db)

static func play_flip(volume_db: float = -2.0) -> void:
	var mgr := _ensure_instance()
	if mgr: mgr._play_random(SFX_CARD_SLIDE, volume_db, 1.04, 1.12)

static func play_click(volume_db: float = -5.0) -> void:
	var mgr := _ensure_instance()
	if mgr: mgr._play_random(SFX_CHIPS, volume_db, 1.10, 1.20)

static func play_match(volume_db: float = -1.0) -> void:
	var mgr := _ensure_instance()
	if mgr:
		mgr._play_random(SFX_CHIPS, volume_db, 1.08, 1.15)
		mgr._play_random(SFX_CARD_PLACE, volume_db - 1.0, 1.02, 1.08)

static func play_invalid(volume_db: float = -1.0) -> void:
	var mgr := _ensure_instance()
	if mgr: mgr._play_random(SFX_DICE_THROW, volume_db, 0.72, 0.78)

static func play_pass(volume_db: float = 0.0) -> void:
	play_knock(volume_db)

static func play_check(volume_db: float = 0.0) -> void:
	play_knock(volume_db)

static func play_place(volume_db: float = 0.0) -> void:
	play_tile_place(volume_db)

static func play_hover() -> void:
	pass

static func play_win() -> void:
	var mgr := _ensure_instance()
	if mgr:
		mgr._play_win_sequence()

func _play_win_sequence() -> void:
	_play_random(SFX_CHIPS, -1.0, 1.0, 1.05)
	var tree := get_tree()
	if tree != null:
		var tw := create_tween()
		tw.tween_interval(0.12)
		tw.tween_callback(func(): _play_random(SFX_CHIPS, -1.0, 1.18, 1.25))
		tw.tween_interval(0.12)
		tw.tween_callback(func(): _play_random(SFX_CARD_PLACE, 0.0, 1.15, 1.22))
		tw.tween_interval(0.12)
		tw.tween_callback(func(): _play_random(SFX_CHIPS, 0.0, 1.35, 1.45))
