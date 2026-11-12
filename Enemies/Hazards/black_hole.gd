extends Node2D

@export var gravity_radius: float = 340.0
@export var event_horizon_radius: float = 22.0
@export var player_pull_strength: float = 215.0
@export var bullet_pull_strength: float = 480.0
@export var asteroid_pull_strength: float = 135.0

var spin_angle: float = 0.0
var pulse_time: float = 0.0

const COLOR_DISK_OUTER: Color = Color(0.75, 0.15, 1.0)
const COLOR_DISK_INNER: Color = Color(1.0, 0.3, 0.35)
const COLOR_HORIZON_RING: Color = Color(1.0, 0.55, 0.85)

func _ready():
	add_to_group("hazards")
	add_to_group("black_holes")

func _physics_process(delta: float):
	spin_angle += delta * 2.2
	pulse_time += delta * 3.0
	
	_pull_player(delta)
	_pull_bullets("player_bullets", delta, true)
	_pull_bullets("enemy_bullets", delta, false)
	_pull_asteroids(delta)
	
	queue_redraw()

func _pull_player(delta: float):
	var player = get_tree().get_first_node_in_group("player")
	if player == null or !is_instance_valid(player) or player.is_dead:
		return
	var to_core: Vector2 = global_position - player.global_position
	var dist: float = to_core.length()
	if dist <= 0.001 or dist > gravity_radius:
		return
		
	var dir: Vector2 = to_core / dist
	if dist < event_horizon_radius:
		if "force_field_state" in player and player.force_field_state == player.ForceFieldState.ACTIVE:
			# Deflect shielded ship outward from singularity
			player.velocity = -dir * 240.0
			player.global_position = global_position - dir * (event_horizon_radius + 10.0)
		elif player.has_method("take_damage"):
			player.take_damage(10.0)
		return
		
	var falloff: float = 1.0 - (dist / gravity_radius)
	var pull: float = player_pull_strength * (0.25 + 1.15 * falloff * falloff)
	player.velocity += dir * pull * delta

func _pull_bullets(group_name: String, delta: float, orient_laser: bool):
	for b in get_tree().get_nodes_in_group(group_name):
		if !is_instance_valid(b) or b.is_queued_for_deletion():
			continue
		var to_core: Vector2 = global_position - b.global_position
		var dist: float = to_core.length()
		if dist > gravity_radius:
			continue
		if dist < event_horizon_radius:
			if b.has_signal("destroyed"):
				b.destroyed.emit()
			b.queue_free()
			continue
		if "velocity" in b:
			var dir: Vector2 = to_core / max(dist, 1.0)
			var falloff: float = 1.0 - (dist / gravity_radius)
			b.velocity += dir * bullet_pull_strength * (0.3 + falloff) * delta
			if orient_laser:
				b.rotation = b.velocity.angle() + PI / 2.0

func _pull_asteroids(delta: float):
	var parent_node := get_parent()
	for a in get_tree().get_nodes_in_group("asteroids"):
		if !is_instance_valid(a) or a.is_queued_for_deletion():
			continue
		if "CLONED" in a and a.CLONED:
			continue
		var to_core: Vector2 = global_position - a.global_position
		var dist: float = to_core.length()
		if dist > gravity_radius:
			continue
		if dist < event_horizon_radius:
			var shrapnel = load("res://effects/vector_shrapnel.gd")
			if shrapnel != null and parent_node != null:
				shrapnel.spawn(parent_node, a.global_position, COLOR_DISK_INNER, 6, 1.1)
			a.queue_free()
			if parent_node != null and parent_node.has_method("_check_wave_cleared"):
				parent_node.call_deferred("_check_wave_cleared")
			continue
		if "linear_velocity" in a:
			var dir: Vector2 = to_core / max(dist, 1.0)
			var falloff: float = 1.0 - (dist / gravity_radius)
			a.linear_velocity += dir * asteroid_pull_strength * (0.25 + falloff) * delta

func _draw():
	# 1. Outer gravitational lensing rings pulsing inward
	for i in range(3):
		var phase: float = fmod(pulse_time * 0.35 + float(i) / 3.0, 1.0)
		var r: float = lerpf(gravity_radius * 0.9, event_horizon_radius + 14.0, phase)
		var alpha: float = (1.0 - phase) * 0.22
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(COLOR_DISK_OUTER.r, COLOR_DISK_OUTER.g, COLOR_DISK_OUTER.b, alpha), 1.4)
		
	# 2. Swirling accretion disk spiral arcs
	for arm in range(3):
		var base_ang: float = spin_angle + float(arm) * (TAU / 3.0)
		for seg in range(5):
			var t0: float = float(seg) / 5.0
			var t1: float = float(seg + 1) / 5.0
			var r0: float = lerpf(event_horizon_radius + 6.0, 88.0, t0)
			var r1: float = lerpf(event_horizon_radius + 6.0, 88.0, t1)
			var a0: float = base_ang - t0 * 1.9
			var a1: float = base_ang - t1 * 1.9
			var col: Color = COLOR_DISK_INNER.lerp(COLOR_DISK_OUTER, t0)
			col.a = (1.0 - t0 * 0.65) * 0.85
			draw_line(Vector2(cos(a0), sin(a0)) * r0, Vector2(cos(a1), sin(a1)) * r1, col, 3.0 - t0 * 1.6)
			
	# 3. Event horizon core & photon ring
	draw_circle(Vector2.ZERO, event_horizon_radius + 6.0, Color(COLOR_DISK_OUTER.r, COLOR_DISK_OUTER.g, COLOR_DISK_OUTER.b, 0.25))
	draw_circle(Vector2.ZERO, event_horizon_radius, Color.BLACK)
	draw_arc(Vector2.ZERO, event_horizon_radius, 0.0, TAU, 36, COLOR_HORIZON_RING, 2.4)
	draw_arc(Vector2.ZERO, event_horizon_radius + 4.0, spin_angle * 1.5, spin_angle * 1.5 + PI * 1.3, 24, COLOR_DISK_INNER, 1.6)

