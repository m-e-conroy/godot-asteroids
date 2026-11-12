extends Node2D

enum Mode { RICOCHET, ASTEROID_CRASH, COMET_SHATTER }

var mode: Mode = Mode.RICOCHET
var base_color: Color = Color(0.5, 1.0, 0.65)
var time_alive: float = 0.0
var max_duration: float = 0.5

var sparks: Array = [] # [{pos, vel, len_scale, width, life, max_life, is_white}]
var chips: Array = []  # [{pos, vel, rot, rot_speed, half_len, life, max_life}]
var rings: Array = []  # [{r_start, r_end, duration, width, col}]

static func spawn_ricochet(parent: Node, pos: Vector2, normal: Vector2, col: Color = Color(0.45, 1.0, 0.55)):
	if parent == null:
		return
	var fx = load("res://effects/impact_fx.gd").new()
	fx.mode = Mode.RICOCHET
	fx.global_position = pos
	fx.base_color = col
	var n := normal.normalized() if normal.length_squared() > 0.0001 else Vector2.UP
	fx._init_ricochet(n)
	parent.add_child(fx)

static func spawn_asteroid_crash(parent: Node, pos: Vector2, contact_normal: Vector2, col: Color = Color.LAWN_GREEN):
	if parent == null:
		return
	var fx = load("res://effects/impact_fx.gd").new()
	fx.mode = Mode.ASTEROID_CRASH
	fx.global_position = pos
	fx.base_color = col
	var n := contact_normal.normalized() if contact_normal.length_squared() > 0.0001 else Vector2.RIGHT
	fx._init_asteroid_crash(n)
	parent.add_child(fx)

static func spawn_comet_shatter(parent: Node, pos: Vector2):
	if parent == null:
		return
	var fx = load("res://effects/impact_fx.gd").new()
	fx.mode = Mode.COMET_SHATTER
	fx.global_position = pos
	fx.base_color = Color(0.45, 0.94, 1.0)
	fx._init_comet_shatter()
	parent.add_child(fx)

func _init_ricochet(normal: Vector2):
	max_duration = 0.42
	# Directional spark streaks bouncing back along the impact normal
	for i in range(9):
		var spread_ang := randf_range(-0.95, 0.95)
		var dir := normal.rotated(spread_ang)
		var spd := randf_range(160.0, 340.0)
		var l_life := randf_range(0.18, 0.34)
		sparks.append({
			"pos": Vector2.ZERO,
			"vel": dir * spd,
			"len_scale": randf_range(0.032, 0.055),
			"width": randf_range(1.4, 2.4),
			"life": l_life,
			"max_life": l_life,
			"is_white": i < 4
		})
	# Tiny rock/surface chips flaking off
	for i in range(4):
		var dir := normal.rotated(randf_range(-1.1, 1.1))
		var l_life := randf_range(0.24, 0.38)
		chips.append({
			"pos": Vector2.ZERO,
			"vel": dir * randf_range(85.0, 175.0),
			"rot": randf() * TAU,
			"rot_speed": randf_range(-14.0, 14.0),
			"half_len": randf_range(2.5, 4.5),
			"life": l_life,
			"max_life": l_life
		})
	_spawn_cpu_burst(normal, 48.0, 14, 90.0, 220.0, 0.28, 1.4, 3.0, base_color)

func _init_asteroid_crash(normal: Vector2):
	max_duration = 0.5
	var tangent := Vector2(-normal.y, normal.x)
	# Contact-point spark shower fanning out along the collision seam
	for i in range(12):
		var side := 1.0 if (i % 2 == 0) else -1.0
		var dir := (tangent * side).rotated(randf_range(-0.55, 0.55))
		var spd := randf_range(120.0, 270.0)
		var l_life := randf_range(0.24, 0.42)
		sparks.append({
			"pos": Vector2.ZERO,
			"vel": dir * spd,
			"len_scale": randf_range(0.035, 0.06),
			"width": randf_range(1.6, 2.6),
			"life": l_life,
			"max_life": l_life,
			"is_white": i % 3 == 0
		})
	# Bits of asteroid flaking off at the contact point
	for i in range(7):
		var dir := Vector2.RIGHT.rotated(randf() * TAU)
		var l_life := randf_range(0.30, 0.48)
		chips.append({
			"pos": Vector2.ZERO,
			"vel": dir * randf_range(65.0, 165.0),
			"rot": randf() * TAU,
			"rot_speed": randf_range(-12.0, 12.0),
			"half_len": randf_range(3.0, 6.0),
			"life": l_life,
			"max_life": l_life
		})
	rings.append({
		"r_start": 4.0,
		"r_end": 26.0,
		"duration": 0.2,
		"width": 2.0,
		"col": base_color
	})
	_spawn_cpu_burst(Vector2.ZERO, 180.0, 22, 65.0, 185.0, 0.36, 1.8, 3.8, base_color)

func _init_comet_shatter():
	max_duration = 0.65
	# Expanding dual-layer frost shockwave rings
	rings.append({
		"r_start": 10.0,
		"r_end": 120.0,
		"duration": 0.44,
		"width": 4.2,
		"col": Color(0.35, 0.92, 1.0)
	})
	rings.append({
		"r_start": 6.0,
		"r_end": 76.0,
		"duration": 0.34,
		"width": 2.4,
		"col": Color(0.9, 0.99, 1.0)
	})
	# Crystalline ice streaks
	for i in range(14):
		var dir := Vector2.RIGHT.rotated((float(i) / 14.0) * TAU + randf_range(-0.18, 0.18))
		var spd := randf_range(150.0, 340.0)
		var l_life := randf_range(0.32, 0.55)
		sparks.append({
			"pos": Vector2.ZERO,
			"vel": dir * spd,
			"len_scale": randf_range(0.04, 0.075),
			"width": randf_range(1.8, 3.0),
			"life": l_life,
			"max_life": l_life,
			"is_white": i % 2 == 0
		})
	_spawn_cpu_burst(Vector2.ZERO, 180.0, 36, 90.0, 280.0, 0.55, 2.0, 4.5, Color(0.75, 0.97, 1.0))

func _spawn_cpu_burst(dir: Vector2, spread_deg: float, amount: int, vel_min: float, vel_max: float, life: float, scale_min: float, scale_max: float, col: Color):
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = amount
	p.lifetime = life
	p.randomness = 0.85
	p.lifetime_randomness = 0.45
	p.direction = dir
	p.spread = spread_deg
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = vel_min
	p.initial_velocity_max = vel_max
	p.damping_min = 60.0
	p.damping_max = 120.0
	p.scale_amount_min = scale_min
	p.scale_amount_max = scale_max
	p.color = col
	add_child(p)
	p.emitting = true

func _process(delta: float):
	time_alive += delta
	for s in sparks:
		if time_alive < s["life"]:
			s["pos"] += s["vel"] * delta
			s["vel"] *= exp(-5.2 * delta)
	for c in chips:
		if time_alive < c["life"]:
			c["pos"] += c["vel"] * delta
			c["vel"] *= exp(-2.8 * delta)
			c["rot"] += c["rot_speed"] * delta
	if time_alive >= max_duration:
		queue_free()
		return
	queue_redraw()

func _draw():
	# Brief impact flash core
	if time_alive < 0.09:
		var ft: float = 1.0 - (time_alive / 0.09)
		var flash_r: float = 12.0 if mode == Mode.COMET_SHATTER else 7.0
		draw_circle(Vector2.ZERO, flash_r * ft, Color(1.0, 1.0, 1.0, ft * 0.85))
		
	# Expanding shockwave / frost rings
	for ring in rings:
		if time_alive < ring["duration"]:
			var rt: float = time_alive / ring["duration"]
			var ease_t: float = 1.0 - pow(1.0 - rt, 2.5)
			var r: float = lerpf(ring["r_start"], ring["r_end"], ease_t)
			var alpha: float = (1.0 - rt) * (1.0 - rt)
			var rcol: Color = ring["col"]
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, Color(rcol.r, rcol.g, rcol.b, alpha * 0.45), ring["width"] * 1.9)
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, Color(1.0, 1.0, 1.0, alpha * 0.9), ring["width"] * 0.75)
			
	# Directional velocity-stretched sparks
	for s in sparks:
		if time_alive >= s["life"]:
			continue
		var alpha: float = 1.0 - (time_alive / s["life"])
		alpha *= alpha
		var tail: Vector2 = s["pos"] - s["vel"] * s["len_scale"]
		var scol: Color = Color.WHITE if s["is_white"] else base_color
		draw_line(tail, s["pos"], Color(base_color.r, base_color.g, base_color.b, alpha * 0.45), s["width"] * 2.1)
		draw_line(tail, s["pos"], Color(scol.r, scol.g, scol.b, alpha * 0.95), s["width"])
		
	# Spinning asteroid/surface chip fragments
	for c in chips:
		if time_alive >= c["life"]:
			continue
		var alpha: float = 1.0 - (time_alive / c["life"])
		var dir: Vector2 = Vector2.RIGHT.rotated(c["rot"]) * c["half_len"]
		draw_line(c["pos"] - dir, c["pos"] + dir, Color(base_color.r, base_color.g, base_color.b, alpha * 0.9), 2.0)

