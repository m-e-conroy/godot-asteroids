extends Node2D

@onready var screen_size: Vector2 = get_viewport_rect().size

var player_node: Node2D = null
var dust_motes: Array = []
var nebula_clouds: Array = []
var anim_time: float = 0.0

const DUST_COUNT: int = 85
const NEBULA_COUNT: int = 7

func _ready():
	z_index = -50
	_init_nebula()
	_init_dust()

func set_player(player: Node2D):
	player_node = player

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

	# Drift space dust motes with parallax
	for m in dust_motes:
		var parallax_vel = -ship_vel * (0.06 * m["depth"])
		m["pos"] += (m["drift"] + parallax_vel) * delta
		m["pos"].x = wrapf(m["pos"].x, 0.0, screen_size.x)
		m["pos"].y = wrapf(m["pos"].y, 0.0, screen_size.y)

	queue_redraw()

func _draw():
	# 1. Soft layered nebula clouds
	for c in nebula_clouds:
		var breathe = 1.0 + sin(anim_time * 0.4 + c["phase"]) * 0.06
		var base_r = c["radius"] * breathe
		var col: Color = c["color"]
		var a: float = c["alpha"]
		
		# 4 concentric soft rings to simulate smooth radial falloff
		draw_circle(c["pos"], base_r, Color(col.r, col.g, col.b, a * 0.35))
		draw_circle(c["pos"], base_r * 0.72, Color(col.r, col.g, col.b, a * 0.55))
		draw_circle(c["pos"], base_r * 0.45, Color(col.r, col.g, col.b, a * 0.8))
		draw_circle(c["pos"], base_r * 0.22, Color(col.r, col.g, col.b, a))

	# 2. Space dust motes
	for m in dust_motes:
		var twinkle = 0.65 + sin(anim_time * 2.5 + m["phase"]) * 0.35
		var col: Color = m["color"]
		var alpha = (0.18 + 0.45 * m["depth"]) * twinkle
		draw_circle(m["pos"], m["size"], Color(col.r, col.g, col.b, alpha))

