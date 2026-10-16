class_name SolitaireFxBurst
extends Control

## Visual effect for Solitaire foundation scoring and ace placement.
## Emits an expanding golden shockwave ring and bursting golden star sparkles.

var elapsed: float = 0.0
var duration: float = 0.45
var particles: Array[Dictionary] = []
var is_ace_burst: bool = false

func _init(center_pos: Vector2 = Vector2.ZERO, p_is_ace: bool = false) -> void:
	position = center_pos
	is_ace_burst = p_is_ace
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 95
	
	duration = 0.5 if is_ace_burst else 0.42
	var count: int = 16 if is_ace_burst else 12
	var base_speed: float = 200.0 if is_ace_burst else 160.0
	
	var colors: Array[Color] = [
		Color(1.0, 0.88, 0.3, 1.0),
		Color(1.0, 0.96, 0.65, 1.0),
		Color(1.0, 1.0, 1.0, 1.0),
		Color(1.0, 0.72, 0.22, 1.0)
	]
	
	for i in range(count):
		var angle: float = (float(i) / float(count)) * TAU + randf_range(-0.18, 0.18)
		var spd: float = randf_range(base_speed * 0.65, base_speed * 1.3)
		var col: Color = colors[randi() % colors.size()]
		var sz: float = randf_range(4.5, 7.5) if not is_ace_burst else randf_range(5.5, 9.0)
		
		particles.append({
			"pos": Vector2.ZERO,
			"vel": Vector2(cos(angle), sin(angle)) * spd,
			"color": col,
			"size": sz,
			"rot": randf_range(0.0, TAU),
			"rot_speed": randf_range(-9.0, 9.0),
			"is_star": randf() > 0.25
		})

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= duration:
		queue_free()
		return
	
	for p in particles:
		p["pos"] += p["vel"] * delta
		p["vel"] *= pow(0.05, delta)
		p["rot"] += p["rot_speed"] * delta
	
	queue_redraw()

func _draw() -> void:
	var t: float = clampf(elapsed / duration, 0.0, 1.0)
	var alpha: float = pow(1.0 - t, 1.3)
	
	# Expanding golden shockwave ring
	var max_radius: float = 85.0 if is_ace_burst else 70.0
	var ring_r: float = lerp(14.0, max_radius, ease(t, 0.4))
	var ring_color := Color(1.0, 0.88, 0.32, alpha * 0.8)
	var ring_width: float = maxf(1.0, (4.0 if is_ace_burst else 3.2) * (1.0 - t))
	draw_arc(Vector2.ZERO, ring_r, 0.0, TAU, 36, ring_color, ring_width, true)
	
	# Particles
	for p in particles:
		var cur_sz: float = p["size"] * (1.0 - t * 0.75)
		var c: Color = p["color"]
		c.a *= alpha
		var p_pos: Vector2 = p["pos"]
		
		if p["is_star"]:
			var rot: float = p["rot"]
			var cos_r: float = cos(rot)
			var sin_r: float = sin(rot)
			
			var pts: PackedVector2Array = [
				p_pos + Vector2(-sin_r * cur_sz, -cos_r * cur_sz),
				p_pos + Vector2(cos_r * cur_sz * 0.28, -sin_r * cur_sz * 0.28),
				p_pos + Vector2(sin_r * cur_sz, cos_r * cur_sz),
				p_pos + Vector2(-cos_r * cur_sz * 0.28, sin_r * cur_sz * 0.28)
			]
			draw_colored_polygon(pts, c)
		else:
			draw_circle(p_pos, cur_sz * 0.55, c)
