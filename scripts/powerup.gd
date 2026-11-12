extends Area2D

enum Type {
	TRIPLE_SHOT,
	RAPID_FIRE,
	EMP_BLAST,
	SHIELD_RECHARGE
}

@export var type: Type = Type.TRIPLE_SHOT
@export var lifetime: float = 15.0

var velocity: Vector2 = Vector2.ZERO
var pulse_time: float = 0.0
var time_alive: float = 0.0
var is_collected: bool = false

@onready var screen_size: Vector2 = get_viewport_rect().size

# Visual Colors
const COLOR_TRIPLE: Color = Color(1.0, 0.8, 0.15)       # Gold / Amber
const COLOR_RAPID: Color = Color(1.0, 0.25, 0.8)        # Hot Magenta
const COLOR_EMP: Color = Color(0.2, 0.95, 1.0)          # Electric Cyan
const COLOR_SHIELD: Color = Color(0.3, 0.7, 1.0)        # Cobalt Blue

func _ready():
	add_to_group("powerups")
	# Randomize initial drift velocity if zero
	if velocity == Vector2.ZERO:
		var rnd = RandomNumberGenerator.new()
		rnd.randomize()
		velocity = Vector2(rnd.randf_range(-25.0, 25.0), rnd.randf_range(-25.0, 25.0))
	
	connect("body_entered", _on_body_entered)

func _process(delta: float):
	time_alive += delta
	pulse_time += delta * 3.5
	
	if time_alive >= lifetime and not is_collected:
		queue_free()
		return
		
	# Move and wrap around screen boundaries
	position += velocity * delta
	position.x = wrapf(position.x, 0.0, screen_size.x)
	position.y = wrapf(position.y, 0.0, screen_size.y)
	
	# Gentle slow tumble
	rotation += delta * 1.2
	
	queue_redraw()

func _on_body_entered(body: Node2D):
	if is_collected:
		return
		
	# Check if collected by player
	if body.is_in_group("player") or body.name == "player" or body.has_method("apply_powerup"):
		is_collected = true
		var sm = get_tree().get_first_node_in_group("score_manager")
		if sm != null:
			sm.add_score(100)
		if body.has_method("apply_powerup"):
			body.apply_powerup(type)
		queue_free()

func _draw():
	# Blink warning during last 3 seconds
	var alpha: float = 1.0
	var time_left: float = lifetime - time_alive
	if time_left < 3.0:
		alpha = 0.3 if fmod(time_left * 8.0, 2.0) < 1.0 else 1.0
		
	# Subtle breathing scale
	var scale_pulse: float = 1.0 + sin(pulse_time) * 0.08
	
	match type:
		Type.TRIPLE_SHOT:
			_draw_triple_shot(Color(COLOR_TRIPLE.r, COLOR_TRIPLE.g, COLOR_TRIPLE.b, alpha), scale_pulse)
		Type.RAPID_FIRE:
			_draw_rapid_fire(Color(COLOR_RAPID.r, COLOR_RAPID.g, COLOR_RAPID.b, alpha), scale_pulse)
		Type.EMP_BLAST:
			_draw_emp_blast(Color(COLOR_EMP.r, COLOR_EMP.g, COLOR_EMP.b, alpha), scale_pulse)
		Type.SHIELD_RECHARGE:
			_draw_shield_recharge(Color(COLOR_SHIELD.r, COLOR_SHIELD.g, COLOR_SHIELD.b, alpha), scale_pulse)

func _draw_outer_diamond(color: Color, s: float):
	var pts: PackedVector2Array = [
		Vector2(0, -14 * s),
		Vector2(14 * s, 0),
		Vector2(0, 14 * s),
		Vector2(-14 * s, 0),
		Vector2(0, -14 * s)
	]
	draw_polyline(pts, Color(color.r, color.g, color.b, color.a * 0.4), 1.0)

func _draw_triple_shot(color: Color, s: float):
	_draw_outer_diamond(color, s)
	# Center dagger
	draw_line(Vector2(0, 8 * s), Vector2(0, -9 * s), color, 2.0)
	draw_line(Vector2(-3 * s, -5 * s), Vector2(0, -9 * s), color, 1.5)
	draw_line(Vector2(3 * s, -5 * s), Vector2(0, -9 * s), color, 1.5)
	# Left angled dagger
	draw_line(Vector2(0, 6 * s), Vector2(-8 * s, -7 * s), color, 1.5)
	draw_line(Vector2(-7 * s, -2 * s), Vector2(-8 * s, -7 * s), color, 1.5)
	# Right angled dagger
	draw_line(Vector2(0, 6 * s), Vector2(8 * s, -7 * s), color, 1.5)
	draw_line(Vector2(7 * s, -2 * s), Vector2(8 * s, -7 * s), color, 1.5)

func _draw_rapid_fire(color: Color, s: float):
	_draw_outer_diamond(color, s)
	# Dual chevron / lightning bolt
	var pts1: PackedVector2Array = [
		Vector2(-7 * s, -3 * s),
		Vector2(0, -9 * s),
		Vector2(7 * s, -3 * s)
	]
	var pts2: PackedVector2Array = [
		Vector2(-7 * s, 4 * s),
		Vector2(0, -2 * s),
		Vector2(7 * s, 4 * s)
	]
	draw_polyline(pts1, color, 2.0)
	draw_polyline(pts2, color, 2.0)
	# Central energy bolt core
	draw_line(Vector2(0, -9 * s), Vector2(0, 8 * s), color, 1.5)

func _draw_emp_blast(color: Color, s: float):
	_draw_outer_diamond(color, s)
	# Central diamond
	var center_pts: PackedVector2Array = [
		Vector2(0, -5 * s),
		Vector2(5 * s, 0),
		Vector2(0, 5 * s),
		Vector2(-5 * s, 0),
		Vector2(0, -5 * s)
	]
	draw_colored_polygon(center_pts, Color(color.r, color.g, color.b, color.a * 0.25))
	draw_polyline(center_pts, color, 2.0)
	# 4 radiating crosshair spikes
	draw_line(Vector2(0, -5 * s), Vector2(0, -11 * s), color, 2.0)
	draw_line(Vector2(0, 5 * s), Vector2(0, 11 * s), color, 2.0)
	draw_line(Vector2(-5 * s, 0), Vector2(-11 * s, 0), color, 2.0)
	draw_line(Vector2(5 * s, 0), Vector2(11 * s, 0), color, 2.0)

func _draw_shield_recharge(color: Color, s: float):
	_draw_outer_diamond(color, s)
	# Hexagonal energy capsule
	var hex_pts: PackedVector2Array = []
	for i in range(7):
		var ang: float = i * (PI / 3.0)
		hex_pts.append(Vector2(cos(ang), sin(ang)) * 8.5 * s)
	draw_polyline(hex_pts, color, 2.0)
	# Inner glowing core
	draw_circle(Vector2.ZERO, 3.0 * s, color)
