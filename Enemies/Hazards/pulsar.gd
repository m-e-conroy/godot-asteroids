extends Node2D

enum PulsarState { COOLDOWN, TELEGRAPH, FIRING }

@export var cooldown_duration: float = 1.6
@export var telegraph_duration: float = 1.25
@export var firing_duration: float = 2.2
@export var idle_spin_speed: float = 0.85
@export var sweep_spin_speed: float = 0.65
@export var beam_length: float = 1500.0
@export var core_radius: float = 18.0

var state: PulsarState = PulsarState.COOLDOWN
var state_timer: float = 1.6
var beam_angle: float = 0.0
var pulse_time: float = 0.0

const COLOR_CORE: Color = Color(0.75, 0.95, 1.0)
const COLOR_RING: Color = Color(1.0, 0.25, 0.85)
const COLOR_WARN: Color = Color(1.0, 0.35, 0.6, 0.75)
const COLOR_BEAM_OUTER: Color = Color(0.95, 0.2, 0.95, 0.55)
const COLOR_BEAM_INNER: Color = Color(0.92, 0.98, 1.0, 0.98)

func _ready():
	add_to_group("hazards")
	add_to_group("pulsars")
	beam_angle = randf() * TAU
	state = PulsarState.COOLDOWN
	state_timer = cooldown_duration

func _physics_process(delta: float):
	pulse_time += delta * 5.0
	state_timer -= delta
	
	match state:
		PulsarState.COOLDOWN:
			beam_angle += idle_spin_speed * delta
			if state_timer <= 0.0:
				state = PulsarState.TELEGRAPH
				state_timer = telegraph_duration
		PulsarState.TELEGRAPH:
			beam_angle += idle_spin_speed * 0.25 * delta
			if state_timer <= 0.0:
				state = PulsarState.FIRING
				state_timer = firing_duration
				var cam_shake = load("res://scripts/camera_shake.gd")
				if cam_shake != null:
					cam_shake.shake(get_tree(), 0.2)
		PulsarState.FIRING:
			beam_angle += sweep_spin_speed * delta
			_check_beam_hits()
			if state_timer <= 0.0:
				state = PulsarState.COOLDOWN
				state_timer = cooldown_duration
				
	_check_core_collision()
	queue_redraw()

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
	var p_start: Vector2 = global_position - dir * beam_length
	var p_end: Vector2 = global_position + dir * beam_length
	var closest: Vector2 = Geometry2D.get_closest_point_to_segment(player.global_position, p_start, p_end)
	if closest.distance_to(player.global_position) <= 13.0:
		if player.has_method("take_damage"):
			player.take_damage(10.0)

func _draw():
	var dir := Vector2.RIGHT.rotated(beam_angle)
	var perp := Vector2(-dir.y, dir.x)
	
	# 1. Sweeping Beams (Telegraph or Firing)
	if state == PulsarState.TELEGRAPH:
		var flicker: float = 0.45 + 0.5 * abs(sin(pulse_time * 4.0))
		var warn_col := Color(COLOR_WARN.r, COLOR_WARN.g, COLOR_WARN.b, flicker)
		draw_dashed_line(-dir * beam_length, dir * beam_length, warn_col, 2.0, 14.0)
	elif state == PulsarState.FIRING:
		var beam_pulse: float = 1.0 + 0.25 * sin(pulse_time * 6.0)
		# Outer plasma glow
		draw_line(-dir * beam_length, dir * beam_length, COLOR_BEAM_OUTER, 10.0 * beam_pulse)
		# Inner white-hot core
		draw_line(-dir * beam_length, dir * beam_length, COLOR_BEAM_INNER, 3.2 * beam_pulse)
		# Emitter nozzle cones
		draw_line(dir * core_radius + perp * 6.0, dir * (core_radius + 14.0), COLOR_CORE, 2.0)
		draw_line(dir * core_radius - perp * 6.0, dir * (core_radius + 14.0), COLOR_CORE, 2.0)
		draw_line(-dir * core_radius + perp * 6.0, -dir * (core_radius + 14.0), COLOR_CORE, 2.0)
		draw_line(-dir * core_radius - perp * 6.0, -dir * (core_radius + 14.0), COLOR_CORE, 2.0)
		
	# 2. Magnetic dipole field rings
	var ring_r: float = core_radius + 8.0 + sin(pulse_time) * 3.0
	draw_arc(Vector2.ZERO, ring_r, 0.0, TAU, 36, Color(COLOR_RING.r, COLOR_RING.g, COLOR_RING.b, 0.45), 1.8)
	draw_arc(Vector2.ZERO, ring_r + 10.0, beam_angle, beam_angle + PI * 0.7, 24, Color(COLOR_CORE.r, COLOR_CORE.g, COLOR_CORE.b, 0.35), 1.4)
	draw_arc(Vector2.ZERO, ring_r + 10.0, beam_angle + PI, beam_angle + PI * 1.7, 24, Color(COLOR_CORE.r, COLOR_CORE.g, COLOR_CORE.b, 0.35), 1.4)
	
	# 3. Neutron star core
	var core_glow := core_radius * (1.2 + 0.15 * sin(pulse_time * 2.0))
	draw_circle(Vector2.ZERO, core_glow, Color(COLOR_RING.r, COLOR_RING.g, COLOR_RING.b, 0.25))
	draw_circle(Vector2.ZERO, core_radius * 0.65, COLOR_CORE)
	draw_arc(Vector2.ZERO, core_radius, 0.0, TAU, 28, COLOR_RING, 2.2)
	
	# Rotating cross-hair ticks
	for i in range(4):
		var a: float = beam_angle + float(i) * (PI / 2.0)
		var v := Vector2.RIGHT.rotated(a)
		draw_line(v * (core_radius * 0.7), v * (core_radius + 5.0), Color.WHITE, 1.8)

