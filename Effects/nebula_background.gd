extends Node2D

@onready var screen_size: Vector2 = get_viewport_rect().size

var player_node: Node2D = null
var dust_motes: Array = []
var nebula_clouds: Array = []
var galaxies: Array = []
var planets: Array = []
var moons: Array = []
var shooting_stars: Array = []

var anim_time: float = 0.0
var shooting_star_timer: float = 6.0
var vista_light_angle: float = -0.65

const DUST_COUNT: int = 85
const NEBULA_COUNT: int = 7

func _ready():
	z_index = -50
	add_to_group("background")
	_init_nebula()
	_init_dust()
	regenerate_vista()

func set_player(player: Node2D):
	player_node = player

func regenerate_vista():
	vista_light_angle = randf_range(-PI, PI)
	shooting_stars.clear()
	shooting_star_timer = randf_range(5.0, 10.0)
	_init_galaxies()
	_init_planets_and_moons()

func _init_nebula():
	nebula_clouds.clear()
	var palette = [
		Color(0.06, 0.38, 0.22), # Deep phosphor emerald
		Color(0.05, 0.25, 0.42), # Void cyan-teal
		Color(0.22, 0.08, 0.36), # Distant amethyst
	]
	for i in range(NEBULA_COUNT):
		var cloud = {
			"pos": Vector2(randf_range(0.0, screen_size.x), randf_range(0.0, screen_size.y)),
			"vel": Vector2(randf_range(-4.0, 4.0), randf_range(-3.0, 3.0)),
			"radius": randf_range(130.0, 260.0),
			"color": palette[i % palette.size()],
			"alpha": randf_range(0.025, 0.055),
			"phase": randf() * TAU
		}
		nebula_clouds.append(cloud)

func _init_dust():
	dust_motes.clear()
	for i in range(DUST_COUNT):
		var depth = randf_range(0.15, 1.0)
		var col_roll = randf()
		var col = Color(0.75, 0.95, 0.85)
		if col_roll < 0.25:
			col = Color(0.25, 0.75, 1.0)
		elif col_roll < 0.45:
			col = Color(0.16, 0.94, 0.0)
			
		var mote = {
			"pos": Vector2(randf_range(0.0, screen_size.x), randf_range(0.0, screen_size.y)),
			"drift": Vector2(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0)) * depth,
			"depth": depth,
			"size": lerpf(0.8, 2.1, depth),
			"color": col,
			"phase": randf() * TAU
		}
		dust_motes.append(mote)

func _init_galaxies():
	galaxies.clear()
	var g_palette = [
		Color(0.42, 0.72, 1.0),
		Color(0.72, 0.45, 1.0),
		Color(0.35, 0.95, 0.72)
	]
	var count: int = 1 if randf() < 0.45 else 2
	for i in range(count):
		var g_dots: Array = []
		var arms: int = 2
		var arm_pts: int = 18
		for arm in range(arms):
			var base_a: float = float(arm) * PI
			for step in range(arm_pts):
				var t: float = float(step) / float(arm_pts)
				var r: float = lerpf(4.0, 52.0, t)
				var ang: float = base_a + t * 2.4 + randf_range(-0.22, 0.22)
				g_dots.append({
					"offset": Vector2(cos(ang) * r, sin(ang) * r * 0.52),
					"size": lerpf(2.2, 0.8, t),
					"alpha": (1.0 - t * 0.75) * randf_range(0.10, 0.20)
				})
		galaxies.append({
			"pos": Vector2(randf_range(100.0, screen_size.x - 100.0), randf_range(90.0, screen_size.y - 90.0)),
			"tilt": randf_range(-0.8, 0.8),
			"color": g_palette[randi() % g_palette.size()],
			"dots": g_dots,
			"parallax": 0.005
		})

func _init_planets_and_moons():
	planets.clear()
	moons.clear()
	var rim_palette = [
		Color(0.28, 0.82, 1.0),   # Ice cyan
		Color(0.22, 0.92, 0.55),  # Phosphor emerald
		Color(0.85, 0.45, 1.0),   # Amethyst
		Color(1.0, 0.62, 0.25),   # Amber gas giant
	]
	var rim_col: Color = rim_palette[randi() % rim_palette.size()]
	var p_pos := Vector2(randf_range(140.0, screen_size.x - 140.0), randf_range(120.0, screen_size.y - 120.0))
	var p_rad: float = randf_range(68.0, 102.0)
	var has_ring: bool = randf() < 0.65
	planets.append({
		"pos": p_pos,
		"radius": p_rad,
		"rim_color": rim_col,
		"body_color": Color(0.015, 0.022, 0.038, 0.92),
		"has_ring": has_ring,
		"ring_tilt": randf_range(-0.55, 0.55),
		"ring_rx": p_rad * randf_range(1.65, 2.05),
		"ring_ry": p_rad * randf_range(0.32, 0.48),
		"parallax": 0.012
	})
	
	# 1-2 companion moons
	var moon_count: int = 1 if randf() < 0.5 else 2
	for i in range(moon_count):
		var m_ang: float = randf() * TAU
		var m_dist: float = p_rad + randf_range(42.0, 110.0)
		var m_pos: Vector2 = p_pos + Vector2(cos(m_ang), sin(m_ang)) * m_dist
		m_pos.x = clamp(m_pos.x, 40.0, screen_size.x - 40.0)
		m_pos.y = clamp(m_pos.y, 40.0, screen_size.y - 40.0)
		moons.append({
			"pos": m_pos,
			"radius": randf_range(13.0, 24.0),
			"rim_color": rim_col.lerp(Color(0.8, 0.95, 1.0), 0.45),
			"body_color": Color(0.02, 0.03, 0.045, 0.90),
			"parallax": 0.018
		})

func _spawn_shooting_star():
	var start_pos := Vector2(randf_range(40.0, screen_size.x - 40.0), randf_range(30.0, screen_size.y * 0.65))
	var dir := Vector2.RIGHT.rotated(randf_range(0.18, 0.78) + (PI if randf() < 0.5 else 0.0))
	var spd: float = randf_range(500.0, 760.0)
	var life: float = randf_range(0.45, 0.72)
	shooting_stars.append({
		"pos": start_pos,
		"vel": dir * spd,
		"life": 0.0,
		"max_life": life,
		"color": Color(0.75, 0.95, 1.0) if randf() < 0.6 else Color(0.75, 1.0, 0.85)
	})

func _process(delta: float):
	anim_time += delta
	
	var ship_vel := Vector2.ZERO
	if player_node != null and is_instance_valid(player_node) and "velocity" in player_node:
		if not ("is_dead" in player_node and player_node.is_dead):
			ship_vel = player_node.velocity

	# Drift nebula clouds
	for c in nebula_clouds:
		c["pos"] += (c["vel"] - ship_vel * 0.025) * delta
		c["pos"].x = wrapf(c["pos"].x, -c["radius"], screen_size.x + c["radius"])
		c["pos"].y = wrapf(c["pos"].y, -c["radius"], screen_size.y + c["radius"])

	# Subtle parallax on galaxies, planets, and moons
	for g in galaxies:
		g["pos"] -= ship_vel * g["parallax"] * delta
		g["pos"].x = wrapf(g["pos"].x, -80.0, screen_size.x + 80.0)
		g["pos"].y = wrapf(g["pos"].y, -80.0, screen_size.y + 80.0)
	for p in planets:
		p["pos"] -= ship_vel * p["parallax"] * delta
		p["pos"].x = wrapf(p["pos"].x, -p["radius"] * 2.2, screen_size.x + p["radius"] * 2.2)
		p["pos"].y = wrapf(p["pos"].y, -p["radius"] * 2.2, screen_size.y + p["radius"] * 2.2)
	for mn in moons:
		mn["pos"] -= ship_vel * mn["parallax"] * delta
		mn["pos"].x = wrapf(mn["pos"].x, -40.0, screen_size.x + 40.0)
		mn["pos"].y = wrapf(mn["pos"].y, -40.0, screen_size.y + 40.0)

	# Drift space dust motes with parallax
	for m in dust_motes:
		var parallax_vel = -ship_vel * (0.06 * m["depth"])
		m["pos"] += (m["drift"] + parallax_vel) * delta
		m["pos"].x = wrapf(m["pos"].x, 0.0, screen_size.x)
		m["pos"].y = wrapf(m["pos"].y, 0.0, screen_size.y)

	# Decorative shooting stars every 5-10s
	shooting_star_timer -= delta
	if shooting_star_timer <= 0.0:
		_spawn_shooting_star()
		shooting_star_timer = randf_range(5.0, 10.0)
		
	for i in range(shooting_stars.size() - 1, -1, -1):
		var st = shooting_stars[i]
		st["life"] += delta
		st["pos"] += st["vel"] * delta
		if st["life"] >= st["max_life"]:
			shooting_stars.remove_at(i)

	queue_redraw()

func _draw():
	# 1. Soft layered nebula clouds
	for c in nebula_clouds:
		var breathe = 1.0 + sin(anim_time * 0.4 + c["phase"]) * 0.06
		var base_r = c["radius"] * breathe
		var col: Color = c["color"]
		var a: float = c["alpha"]
		
		draw_circle(c["pos"], base_r, Color(col.r, col.g, col.b, a * 0.35))
		draw_circle(c["pos"], base_r * 0.72, Color(col.r, col.g, col.b, a * 0.55))
		draw_circle(c["pos"], base_r * 0.45, Color(col.r, col.g, col.b, a * 0.8))
		draw_circle(c["pos"], base_r * 0.22, Color(col.r, col.g, col.b, a))

	# 2. Distant spiral galaxies
	for g in galaxies:
		var gcol: Color = g["color"]
		draw_circle(g["pos"], 14.0, Color(gcol.r, gcol.g, gcol.b, 0.06))
		draw_circle(g["pos"], 5.5, Color(1.0, 1.0, 1.0, 0.14))
		for d in g["dots"]:
			var rot_off: Vector2 = d["offset"].rotated(g["tilt"])
			draw_circle(g["pos"] + rot_off, d["size"], Color(gcol.r, gcol.g, gcol.b, d["alpha"]))

	# 3. Soft shaded planets with atmospheric rim glow & optional rings
	for p in planets:
		_draw_shaded_body(p["pos"], p["radius"], p["body_color"], p["rim_color"], p["has_ring"], p["ring_tilt"], p["ring_rx"], p["ring_ry"])

	# 4. Companion moons
	for mn in moons:
		_draw_shaded_body(mn["pos"], mn["radius"], mn["body_color"], mn["rim_color"], false, 0.0, 0.0, 0.0)

	# 5. Space dust motes
	for m in dust_motes:
		var twinkle = 0.65 + sin(anim_time * 2.5 + m["phase"]) * 0.35
		var col: Color = m["color"]
		var alpha = (0.18 + 0.45 * m["depth"]) * twinkle
		draw_circle(m["pos"], m["size"], Color(col.r, col.g, col.b, alpha))

	# 6. Occasional decorative shooting stars
	for st in shooting_stars:
		var t: float = st["life"] / st["max_life"]
		var env: float = sin(t * PI)
		var scol: Color = st["color"]
		var tail_pos: Vector2 = st["pos"] - st["vel"] * 0.09
		draw_line(tail_pos, st["pos"], Color(scol.r, scol.g, scol.b, env * 0.22), 3.2)
		draw_line(tail_pos.lerp(st["pos"], 0.45), st["pos"], Color(1.0, 1.0, 1.0, env * 0.55), 1.4)
		draw_circle(st["pos"], 1.8, Color(1.0, 1.0, 1.0, env * 0.7))

func _draw_shaded_body(pos: Vector2, r: float, body_col: Color, rim_col: Color, has_ring: bool, tilt: float, rx: float, ry: float):
	# Back half of planetary ring (behind planet)
	if has_ring:
		_draw_ring_arc(pos, rx, ry, tilt, PI, TAU, Color(rim_col.r, rim_col.g, rim_col.b, 0.14), 3.0)
		_draw_ring_arc(pos, rx * 0.84, ry * 0.84, tilt, PI, TAU, Color(rim_col.r, rim_col.g, rim_col.b, 0.09), 1.8)
		
	# Soft outer atmospheric halo
	draw_circle(pos, r * 1.14, Color(rim_col.r, rim_col.g, rim_col.b, 0.04))
	draw_circle(pos, r * 1.05, Color(rim_col.r, rim_col.g, rim_col.b, 0.07))
	
	# Dark shaded silhouette disc
	draw_circle(pos, r, body_col)
	
	# Directional crescent rim glow
	var a_start: float = vista_light_angle - 1.25
	var a_end: float = vista_light_angle + 1.25
	draw_arc(pos, r, a_start, a_end, 40, Color(rim_col.r, rim_col.g, rim_col.b, 0.12), 4.5)
	draw_arc(pos, r - 0.5, vista_light_angle - 0.95, vista_light_angle + 0.95, 36, Color(rim_col.r, rim_col.g, rim_col.b, 0.24), 2.0)
	draw_arc(pos, r, 0.0, TAU, 48, Color(rim_col.r, rim_col.g, rim_col.b, 0.07), 1.0)
	
	# Front half of planetary ring (in front of planet)
	if has_ring:
		_draw_ring_arc(pos, rx, ry, tilt, 0.0, PI, Color(rim_col.r, rim_col.g, rim_col.b, 0.18), 3.2)
		_draw_ring_arc(pos, rx * 0.84, ry * 0.84, tilt, 0.0, PI, Color(rim_col.r, rim_col.g, rim_col.b, 0.11), 1.8)

func _draw_ring_arc(center: Vector2, rx: float, ry: float, tilt: float, a_from: float, a_to: float, col: Color, width: float):
	var pts := PackedVector2Array()
	var steps: int = 24
	for i in range(steps + 1):
		var a: float = lerpf(a_from, a_to, float(i) / float(steps))
		var pt := Vector2(cos(a) * rx, sin(a) * ry).rotated(tilt)
		pts.append(center + pt)
	draw_polyline(pts, col, width)
