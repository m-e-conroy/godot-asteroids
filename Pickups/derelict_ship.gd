extends Area2D

@export var drift_speed: float = 54.0
@export var collect_radius: float = 46.0

var drift_dir: Vector2 = Vector2.RIGHT
var rot_speed: float = 0.45
var pulse_time: float = 0.0
var sparks: Array = []

var vector_shrapnel_script = preload("res://effects/vector_shrapnel.gd")

@onready var screen_size: Vector2 = get_viewport_rect().size

const COLOR_AMBER: Color = Color(1.0, 0.65, 0.12)
const COLOR_AMBER_DIM: Color = Color(0.75, 0.38, 0.05)
const COLOR_BEACON: Color = Color(1.0, 0.28, 0.1)
const EXIT_MARGIN: float = 120.0

func _ready():
	add_to_group("powerups")
	add_to_group("salvage")
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	body_entered.connect(_on_body_entered)
	rot_speed = randf_range(0.35, 0.7) * (-1.0 if randf() < 0.5 else 1.0)
	_spawn_spark_particles()

func setup_drift(start_pos: Vector2, target_pos: Vector2, speed: float = 54.0):
	global_position = start_pos
	drift_speed = speed
	drift_dir = (target_pos - start_pos).normalized()

func _spawn_spark_particles():
	var p := CPUParticles2D.new()
	p.amount = 10
	p.lifetime = 0.55
	p.randomness = 0.8
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 8.0
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 12.0
	p.initial_velocity_max = 38.0
	p.scale_amount_min = 1.2
	p.scale_amount_max = 2.4
	p.color = Color(1.0, 0.78, 0.25, 0.9)
	add_child(p)
	p.emitting = true

func _physics_process(delta: float):
	pulse_time += delta * 6.0
	global_position += drift_dir * drift_speed * delta
	rotation += rot_speed * delta
	
	# Periodic electrical short-circuit spark lines
	if randf() < 0.22:
		var ang := randf() * TAU
		sparks.append({
			"pos": Vector2(randf_range(-8.0, 8.0), randf_range(-8.0, 8.0)),
			"vel": Vector2.RIGHT.rotated(ang) * randf_range(28.0, 75.0),
			"life": 0.28,
			"max_life": 0.28
		})
	for i in range(sparks.size() - 1, -1, -1):
		var s = sparks[i]
		s["pos"] += s["vel"] * delta
		s["life"] -= delta
		if s["life"] <= 0.0:
			sparks.remove_at(i)
			
	if global_position.x < -EXIT_MARGIN or global_position.x > screen_size.x + EXIT_MARGIN \
	or global_position.y < -EXIT_MARGIN or global_position.y > screen_size.y + EXIT_MARGIN:
		queue_free()
		return
		
	var player = get_tree().get_first_node_in_group("player")
	if player != null and is_instance_valid(player) and not ("is_dead" in player and player.is_dead):
		if global_position.distance_to(player.global_position) <= collect_radius:
			_on_body_entered(player)
			return
		
	queue_redraw()

func _draw():
	# Flickering amber phosphor intensity
	var flicker: float = 0.55 + 0.45 * abs(sin(pulse_time * 2.3))
	if fmod(pulse_time, 3.7) > 3.35:
		flicker *= 0.35
	var hull_col := Color(COLOR_AMBER.r, COLOR_AMBER.g, COLOR_AMBER.b, flicker)
	var halo_col := Color(COLOR_AMBER.r, COLOR_AMBER.g, COLOR_AMBER.b, flicker * 0.32)
	
	# Broken wireframe ship hull (intact port side, sheared starboard wing)
	var intact_hull := PackedVector2Array([
		Vector2(0, -17),
		Vector2(-9, 11),
		Vector2(0, 6),
		Vector2(4, 1),
		Vector2(7, -4),
		Vector2(0, -17)
	])
	draw_polyline(intact_hull, halo_col, 4.8)
	draw_polyline(intact_hull, hull_col, 2.0)
	
	# Snapped/detached starboard strut fragment
	draw_line(Vector2(4, 1), Vector2(10, 9), Color(COLOR_AMBER_DIM.r, COLOR_AMBER_DIM.g, COLOR_AMBER_DIM.b, flicker * 0.8), 1.6)
	draw_line(Vector2(-3, -6), Vector2(3, -1), Color(COLOR_AMBER_DIM.r, COLOR_AMBER_DIM.g, COLOR_AMBER_DIM.b, flicker * 0.7), 1.3)
	
	# Blinking distress beacon
	var beacon_on: bool = sin(pulse_time * 1.4) > 0.1
	if beacon_on:
		draw_circle(Vector2(0, -4), 4.5, Color(COLOR_BEACON.r, COLOR_BEACON.g, COLOR_BEACON.b, 0.45))
		draw_circle(Vector2(0, -4), 2.0, Color.WHITE)
		
	# Short-circuit spark streaks
	for s in sparks:
		var a: float = clamp(s["life"] / s["max_life"], 0.0, 1.0)
		var tail: Vector2 = s["pos"] - s["vel"] * 0.05
		draw_line(tail, s["pos"], Color(1.0, 0.88, 0.4, a), 1.5)

func _on_body_entered(body: Node):
	if body == null or !body.is_in_group("player"):
		return
	if "is_dead" in body and body.is_dead:
		return
	if body.has_method("apply_salvage_upgrade"):
		var info: Dictionary = body.apply_salvage_upgrade()
		var parent_node := get_parent()
		if parent_node != null and vector_shrapnel_script != null:
			vector_shrapnel_script.spawn(parent_node, global_position, COLOR_AMBER, 10, 1.2)
		var am = load("res://scripts/audio_manager.gd")
		if am != null:
			am.play_powerup(get_tree())
		var hud = get_tree().get_first_node_in_group("hud")
		if hud != null and hud.has_method("announce_salvage"):
			hud.announce_salvage(info.get("title", "SALVAGE ACQUIRED"), info.get("color", COLOR_AMBER))
		queue_free()

