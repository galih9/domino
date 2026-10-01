class_name SoundManager
extends Node

## Procedural audio manager for Domino game.
## Synthesizes realistic tile clacks, slides, flips, shuffling, and UI sounds
## without requiring any external audio files.

static var instance: SoundManager = null


var _player_pool: Array[AudioStreamPlayer] = []
var _pool_size: int = 8
var _pool_index: int = 0

var sfx_place: AudioStreamWAV
var sfx_deal: AudioStreamWAV
var sfx_flip: AudioStreamWAV
var sfx_shuffle: AudioStreamWAV
var sfx_draw: AudioStreamWAV
var sfx_hover: AudioStreamWAV
var sfx_click: AudioStreamWAV
var sfx_pass: AudioStreamWAV
var sfx_win: AudioStreamWAV

func _enter_tree() -> void:
	instance = self

func _ready() -> void:
	_init_audio_pool()
	_generate_all_sfx()

func _init_audio_pool() -> void:
	for i in range(_pool_size):
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_player_pool.append(player)

func _play_stream(stream: AudioStreamWAV, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if stream == null or _player_pool.is_empty():
		return
	var player: AudioStreamPlayer = _player_pool[_pool_index]
	_pool_index = (_pool_index + 1) % _pool_size
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()

# Public playback methods
func play_place() -> void:
	var pitch: float = randf_range(0.92, 1.08)
	_play_stream(sfx_place, -2.0, pitch)

func play_deal() -> void:
	var pitch: float = randf_range(0.95, 1.05)
	_play_stream(sfx_deal, -4.0, pitch)

func play_flip() -> void:
	var pitch: float = randf_range(0.96, 1.04)
	_play_stream(sfx_flip, -3.0, pitch)

func play_shuffle() -> void:
	_play_stream(sfx_shuffle, -2.0, randf_range(0.95, 1.05))

func play_draw() -> void:
	_play_stream(sfx_draw, -3.0, randf_range(0.95, 1.05))

func play_hover() -> void:
	_play_stream(sfx_hover, -10.0, 1.0)

func play_click() -> void:
	_play_stream(sfx_click, -4.0, 1.0)

func play_pass() -> void:
	_play_stream(sfx_pass, -2.0, 1.0)

func play_win() -> void:
	_play_stream(sfx_win, 0.0, 1.0)

# Procedural Sound Synthesis
func _generate_all_sfx() -> void:
	sfx_place = _gen_clack()
	sfx_deal = _gen_swoosh()
	sfx_flip = _gen_flip()
	sfx_shuffle = _gen_shuffle()
	sfx_draw = _gen_swoosh(0.18, 550.0)
	sfx_hover = _gen_tone(0.03, 1400.0, 0.15)
	sfx_click = _gen_tone(0.04, 980.0, 0.3)
	sfx_pass = _gen_knock()
	sfx_win = _gen_fanfare()

func _create_wav(byte_data: PackedByteArray, sample_rate: int = 22050) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = byte_data
	return wav

## Generates a realistic domino tile clack (impact + ceramic resonance)
func _gen_clack() -> AudioStreamWAV:
	var rate: int = 22050
	var dur: float = 0.09
	var n_samples: int = int(rate * dur)
	var bytes := PackedByteArray()
	bytes.resize(n_samples * 2)

	for i in range(n_samples):
		var t: float = float(i) / rate
		var env: float = exp(-t * 55.0)
		# Mix of impact transient, body resonance (~520Hz) and high overtone (~1850Hz)
		var body: float = sin(TAU * 520.0 * t) * 0.65
		var high: float = sin(TAU * 1850.0 * t) * 0.25
		var noise: float = (randf() * 2.0 - 1.0) * exp(-t * 120.0) * 0.3
		var sample: float = (body + high + noise) * env * 28000.0
		bytes.encode_s16(i * 2, int(clampf(sample, -32767.0, 32767.0)))

	return _create_wav(bytes, rate)

## Generates smooth sliding swoosh
func _gen_swoosh(dur: float = 0.15, base_freq: float = 650.0) -> AudioStreamWAV:
	var rate: int = 22050
	var n_samples: int = int(rate * dur)
	var bytes := PackedByteArray()
	bytes.resize(n_samples * 2)

	for i in range(n_samples):
		var progress: float = float(i) / n_samples
		var env: float = sin(progress * PI)
		var t: float = float(i) / rate
		var freq: float = base_freq + (progress * 300.0)
		var noise: float = (randf() * 2.0 - 1.0) * 0.4
		var wave: float = sin(TAU * freq * t) * 0.6
		var sample: float = (wave + noise) * env * 18000.0
		bytes.encode_s16(i * 2, int(clampf(sample, -32767.0, 32767.0)))

	return _create_wav(bytes, rate)

## Generates tile flip snap
func _gen_flip() -> AudioStreamWAV:
	var rate: int = 22050
	var dur: float = 0.07
	var n_samples: int = int(rate * dur)
	var bytes := PackedByteArray()
	bytes.resize(n_samples * 2)

	for i in range(n_samples):
		var t: float = float(i) / rate
		var env: float = exp(-t * 60.0)
		var freq: float = lerp(900.0, 320.0, float(i) / n_samples)
		var sample: float = sin(TAU * freq * t) * env * 26000.0
		bytes.encode_s16(i * 2, int(clampf(sample, -32767.0, 32767.0)))

	return _create_wav(bytes, rate)

## Generates multi-tile shuffle rustle sound
func _gen_shuffle() -> AudioStreamWAV:
	var rate: int = 22050
	var dur: float = 0.65
	var n_samples: int = int(rate * dur)
	var bytes := PackedByteArray()
	bytes.resize(n_samples * 2)

	# Clack hit timestamps
	var hits: Array[float] = [0.03, 0.11, 0.19, 0.28, 0.36, 0.45, 0.53]

	for i in range(n_samples):
		var t: float = float(i) / rate
		var sample: float = 0.0
		for hit in hits:
			if t >= hit:
				var dt: float = t - hit
				if dt < 0.08:
					var env: float = exp(-dt * 50.0)
					var tone: float = sin(TAU * (480.0 + sin(hit * 10.0) * 80.0) * dt)
					var n: float = (randf() * 2.0 - 1.0) * 0.3 * exp(-dt * 100.0)
					sample += (tone + n) * env * 9000.0
		bytes.encode_s16(i * 2, int(clampf(sample, -32767.0, 32767.0)))

	return _create_wav(bytes, rate)

## Generates a simple decayed tone
func _gen_tone(dur: float, freq: float, max_vol: float) -> AudioStreamWAV:
	var rate: int = 22050
	var n_samples: int = int(rate * dur)
	var bytes := PackedByteArray()
	bytes.resize(n_samples * 2)

	for i in range(n_samples):
		var t: float = float(i) / rate
		var env: float = exp(-t * (1.0 / (dur * 0.35)))
		var sample: float = sin(TAU * freq * t) * env * (32767.0 * max_vol)
		bytes.encode_s16(i * 2, int(clampf(sample, -32767.0, 32767.0)))

	return _create_wav(bytes, rate)

## Generates hollow knock for pass
func _gen_knock() -> AudioStreamWAV:
	var rate: int = 22050
	var dur: float = 0.14
	var n_samples: int = int(rate * dur)
	var bytes := PackedByteArray()
	bytes.resize(n_samples * 2)

	for i in range(n_samples):
		var t: float = float(i) / rate
		var env: float = exp(-t * 30.0)
		var tone: float = sin(TAU * 210.0 * t) + 0.3 * sin(TAU * 340.0 * t)
		var sample: float = tone * env * 24000.0
		bytes.encode_s16(i * 2, int(clampf(sample, -32767.0, 32767.0)))

	return _create_wav(bytes, rate)

## Generates winning chord fanfare (C5, E5, G5, C6 arpeggio)
func _gen_fanfare() -> AudioStreamWAV:
	var rate: int = 22050
	var dur: float = 0.8
	var n_samples: int = int(rate * dur)
	var bytes := PackedByteArray()
	bytes.resize(n_samples * 2)

	var notes: Array[float] = [523.25, 659.25, 783.99, 1046.5] # C5, E5, G5, C6
	var note_dur: float = 0.15

	for i in range(n_samples):
		var t: float = float(i) / rate
		var sample: float = 0.0
		for n_idx in range(notes.size()):
			var start_t: float = n_idx * note_dur
			if t >= start_t:
				var dt: float = t - start_t
				var env: float = exp(-dt * 3.5)
				var tone: float = sin(TAU * notes[n_idx] * dt) * 0.7 + sin(TAU * notes[n_idx] * 2.0 * dt) * 0.2
				sample += tone * env * 7000.0
		bytes.encode_s16(i * 2, int(clampf(sample, -32767.0, 32767.0)))

	return _create_wav(bytes, rate)
