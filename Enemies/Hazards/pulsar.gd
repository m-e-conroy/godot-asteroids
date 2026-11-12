extends CharacterBody2D

signal destroyed(pos: Vector2)

enum PulsarState { COOLDOWN, TELEGRAPH, FIRING }

@export var cooldown_duration: float = 3.5
@export var telegraph_duration: float = 1.4
@export var firing_duration: float = 1.4
@export var idle_spin_speed: float = 0.85
@export var sweep_spin_speed: float = 0.35
@export var beam_length: float = 1500.0
@export var core_radius: float = 18.0
@export var max_health: int = 12
@export var score_value: int = 400

var health: int = 12
var state: PulsarState = PulsarState.COOLDOWN
var state_timer: float = 3.5
var beam_angle: float = 0.0
var pulse_time: float = 0.0
var flash_time: float = 0.0

var beam_end_pos: float = 1500.0
var beam_end_neg: float = 1500.0
var hit_pos_blocked: bool = false
var hit_neg_blocked: bool = false

var powerup_scene = preload("res://Pickups/powerup.tscn")

const COLOR_CORE: Color = Color(0.75, 0.95, 1.0)
const COLOR_RING: Color = Color(1.0, 0.25, 0.85)
const COLOR_WARN: Color = Color(1.0, 0.35, 0.6, 0.75)
const COLOR_BEAM_OUTER: Color = Color(0.95, 0.2, 0.95, 0.55)
const COLOR_BEAM_INNER: Color = Color(0.92, 0.98, 1.0, 0.98)

func _ready():
	add_to_group("hazards")
	add_to_group("pulsars")
	collision_layer = 2
	collision_mask = 1
	health = max_health
	beam_angle = randf() * TAU
	state = PulsarState.COOLDOWN
	state_timer = cooldown_duration

func _physics_process(delta: float):
	pulse_time += delta * 5.0
	if flash_time > 0.0:
		flash_time -= delta
	state_timer -= delta
	
	match state:
		PulsarState.COOLDOWN:
			beam_angle += idle_spin_speed * delta
			if state_timer <= 0.0:
				state = PulsarState.TELEGRAPH
				state_timer = telegraph_duration
		PulsarState.TELEGRAPH:
			beam_angle += idle_spin_speed * 0.25 * delta
			_update_beam_occlusions()
			if state_timer <= 0.0:
				state = PulsarState.FIRING
				state_timer = firing_duration
				var cam_shake = load("res://scripts/camera_shake.gd")
				if cam_shake != null:
					cam_shake.shake(get_tree(), 0.2)
		PulsarState.FIRING:
			beam_angle += sweep_spin_speed * delta
			_update_beam_occlusions()
			_check_beam_hits()
			if state_timer <= 0.0:
				state = PulsarState.COOLDOWN
				state_timer = cooldown_duration
				
	_check_core_collision()
	queue_redraw()

func _update_beam_occlusions():
	var dir := Vector2.RIGHT.rotated(beam_angle)
	var res_pos := _raycast_asteroids(dir)
	beam_end_pos = res_pos["dist"]
	hit_pos_blocked = res_pos["blocked"]
	
	var res_neg := _raycast_asteroids(-dir)
	beam_end_neg = res_neg["dist"]
	hit_neg_blocked = res_neg["blocked"]

func _raycast_asteroids(ray_dir: Vector2) -> Dictionary:
	var min_dist: float = beam_length
	var blocked: bool = false
	for a in get_tree().get_nodes_in_group("asteroids"):
		if !is_instance_valid(a) or a.is_queued_for_deletion():
			continue
		var ast_r: float = (a.radius * 0.85) if "radius" in a else 30.0
		var to_ast: Vector2 = a.global_position - global_position
		var proj: float = to_ast.dot(ray_dir)
		if proj <= core_radius or proj >= min_dist:
			continue
		var perp_sq: float = to_ast.length_squared() - proj * proj
		var r_sq: float = ast_r * ast_r
		if perp_sq < r_sq:
			var hit_dist: float = proj - sqrt(r_sq - perp_sq)
			if hit_dist > core_radius and hit_dist < min_dist:
				min_dist = hit_dist
				blocked = true
	return {"dist": min_dist, "blocked": blocked}

func _check_core_collision():
	var player = get_tree().get_first_node_in_group("player")
	if player == null or !is_instance_valid(player) or player.is_dead:
		return
	if global_position.distance_to(player.global_position) <= core_radius + 8.0:
		if player.has_method("take_damage"):
			player.take_damage(10.0)

func _check_beam_hits():
	var player = get_tree().get_first_node_in_group("player")
	if player == null or !is_instance_valid(player) or player.is_dead:
		return
	var dir := Vector2.RIGHT.rotated(beam_angle)
	var p_neg: Vector2 = global_position - dir * beam_end_neg
	var p_pos: Vector2 = global_position + dir * beam_end_pos
	var closest: Vector2 = Geometry2D.get_closest_point_to_segment(player.global_position, p_neg, p_pos)
	if closest.distance_to(player.global_position) <= 9.0:
		if player.has_method("take_damage"):
			player.take_damage(10.0)

func take_damage(amount: int = 1):
	health -= amount
	flash_time = 0.08
	if health <= 0:
		_destroy_pulsar()

func takeDamange():
	take_damage(1)

func _destroy_pulsar():
	if is_queued_for_deletion():
		return
	var parent_node := get_parent()
	if parent_node != null:
		var sm = get_tree().get_first_node_in_group("score_manager")
		if sm != null:
			sm.add_score(score_value, global_position)
			
		var pu = powerup_scene.instantiate()
		pu.global_position = global_position
		parent_node.call_deferred("add_child", pu)
		
		var shrapnel = load("res://effects/vector_shrapnel.gd")
		if shrapnel != null:
			shrapnel.spawn(parent_node, global_position, COLOR_RING, 14, 1.5)
			
		var am = load("res://scripts/audio_manager.gd")
		if am != null:
			am.play_explosion(get_tree(), true)
			
		var cam_shake = load("res://scripts/camera_shake.gd")
		if cam_shake != null:
			cam_shake.shake(get_tree(), 0.45)
			
	destroyed.emit(global_position)
	queue_free()

func _draw():
	var dir := Vector2.RIGHT.rotated(beam_angle)
	var perp := Vector2(-dir.y, dir.x)
	var p_neg: Vector2 = -dir * beam_end_neg
	var p_pos: Vector2 = dir * beam_end_pos
	
	# 1. Sweeping Beams (Telegraph or Firing), clipped by asteroids
	if state == PulsarState.TELEGRAPH:
		var flicker: float = 0.45 + 0.5 * abs(sin(pulse_time * 4.0))
		var warn_col := Color(COLOR_WARN.r, COLOR_WARN.g, COLOR_WARN.b, flicker)
		draw_dashed_line(p_neg, p_pos, warn_col, 2.0, 14.0)
	elif state == PulsarState.FIRING:
		var beam_pulse: float = 1.0 + 0.25 * sin(pulse_time * 6.0)
		draw_line(p_neg, p_pos, COLOR_BEAM_OUTER, 9.0 * beam_pulse)
		draw_line(p_neg, p_pos, COLOR_BEAM_INNER, 2.8 * beam_pulse)
		# Emitter nozzle cones
		draw_line(dir * core_radius + perp * 6.0, dir * (core_radius + 14.0), COLOR_CORE, 2.0)
		draw_line(dir * core_radius - perp * 6.0, dir * (core_radius + 14.0), COLOR_CORE, 2.0)
		draw_line(-dir * core_radius + perp * 6.0, -dir * (core_radius + 14.0), COLOR_CORE, 2.0)
		draw_line(-dir * core_radius - perp * 6.0, -dir * (core_radius + 14.0), COLOR_CORE, 2.0)
		# Asteroid occlusion impact flares
		if hit_pos_blocked:
			draw_circle(p_pos, 6.0 * beam_pulse, COLOR_BEAM_OUTER)
			draw_circle(p_pos, 3.0, Color.WHITE)
		if hit_neg_blocked:
			draw_circle(p_neg, 6.0 * beam_pulse, COLOR_BEAM_OUTER)
			draw_circle(p_neg, 3.0, Color.WHITE)
		
	# 2. Magnetic dipole field rings & HP arc
	var ring_r: float = core_radius + 8.0 + sin(pulse_time) * 3.0
	draw_arc(Vector2.ZERO, ring_r, 0.0, TAU, 36, Color(COLOR_RING.r, COLOR_RING.g, COLOR_RING.b, 0.45), 1.8)
	if health < max_health:
		var hp_ratio: float = clamp(float(health) / float(max_health), 0.0, 1.0)
		draw_arc(Vector2.ZERO, core_radius + 4.5, -PI / 2.0, -PI / 2.0 + hp_ratio * TAU, 28, COLOR_CORE, 2.2)
	draw_arc(Vector2.ZERO, ring_r + 10.0, beam_angle, beam_angle + PI * 0.7, 24, Color(COLOR_CORE.r, COLOR_CORE.g, COLOR_CORE.b, 0.35), 1.4)
	draw_arc(Vector2.ZERO, ring_r + 10.0, beam_angle + PI, beam_angle + PI * 1.7, 24, Color(COLOR_CORE.r, COLOR_CORE.g, COLOR_CORE.b, 0.35), 1.4)
	
	# 3. Neutron star core
	var c_col: Color = Color.WHITE if flash_time > 0.0 else COLOR_CORE
	var r_col: Color = Color.WHITE if flash_time > 0.0 else COLOR_RING
	var core_glow := core_radius * (1.2 + 0.15 * sin(pulse_time * 2.0))
	draw_circle(Vector2.ZERO, core_glow, Color(r_col.r, r_col.g, r_col.b, 0.25))
	draw_circle(Vector2.ZERO, core_radius * 0.65, c_col)
	draw_arc(Vector2.ZERO, core_radius, 0.0, TAU, 28, r_col, 2.2)
	
	# Rotating cross-hair ticks
	for i in range(4):
		var a: float = beam_angle + float(i) * (PI / 2.0)
		var v := Vector2.RIGHT.rotated(a)
		draw_line(v * (core_radius * 0.7), v * (core_radius + 5.0), Color.WHITE, 1.8)
