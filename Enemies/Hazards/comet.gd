extends CharacterBody2D

signal shattered(pos: Vector2)

@export var speed: float = 410.0
@export var max_health: int = 8
@export var score_value: int = 500

var health: int = 8
var travel_dir: Vector2 = Vector2.RIGHT
var flash_time: float = 0.0
var trail_points: Array[Vector2] = []
var debris_sparks: Array = [] # [{pos: Vector2, vel: Vector2, life: float, max_life: float}]
var spin_angle: float = 0.0

var rock_crash_scene = preload("res://effects/rock_crash.tscn")
var powerup_scene = preload("res://Pickups/powerup.tscn")

@onready var screen_size: Vector2 = get_viewport_rect().size

const COLOR_ICE_CORE: Color = Color(0.85, 0.98, 1.0)
const COLOR_ICE_GLOW: Color = Color(0.25, 0.85, 1.0)
const COLOR_TAIL: Color = Color(0.35, 0.9, 1.0)
const EXIT_MARGIN: float = 160.0

func _ready():
	add_to_group("hazards")
	add_to_group("comets")
	collision_layer = 2
	collision_mask = 1
	health = max_health
	velocity = travel_dir.normalized() * speed
	
	var shape := CircleShape2D.new()
	shape.radius = 16.0
	$CollisionShape2D.shape = shape

func setup_transit(start_pos: Vector2, target_pos: Vector2, comet_speed: float = 410.0):
	global_position = start_pos
	speed = comet_speed
	travel_dir = (target_pos - start_pos).normalized()
	velocity = travel_dir * speed

func _physics_process(delta: float):
	spin_angle += delta * 4.5
	if flash_time > 0.0:
		flash_time -= delta
		
	# Record trail
	trail_points.push_front(global_position)
	if trail_points.size() > 26:
		trail_points.pop_back()
		
	# Spawn icy debris sparks along tail
	if randf() < 0.65:
		var jitter := Vector2(randf_range(-35.0, 35.0), randf_range(-35.0, 35.0))
		debris_sparks.append({
			"pos": global_position - travel_dir * 10.0 + Vector2(randf_range(-6.0, 6.0), randf_range(-6.0, 6.0)),
			"vel": -travel_dir * randf_range(30.0, 90.0) + jitter,
			"life": 0.45,
			"max_life": 0.45
		})
		
	for i in range(debris_sparks.size() - 1, -1, -1):
		var s = debris_sparks[i]
		s["pos"] += s["vel"] * delta
		s["life"] -= delta
		if s["life"] <= 0.0:
			debris_sparks.remove_at(i)
			
	var collision := move_and_collide(velocity * delta)
	if collision:
		var col_obj := collision.get_collider()
		if col_obj != null:
			if col_obj.is_in_group("player"):
				if col_obj.has_method("take_damage"):
					col_obj.take_damage(10.0)
				if "force_field_state" in col_obj and col_obj.force_field_state == col_obj.ForceFieldState.ACTIVE:
					_shatter(false)
					return
			elif col_obj.is_in_group("asteroids"):
				if col_obj.has_method("take_damage"):
					col_obj.take_damage(999)
				_shatter(false)
				return
				
	# Despawn cleanly once well outside screen bounds
	if global_position.x < -EXIT_MARGIN or global_position.x > screen_size.x + EXIT_MARGIN \
	or global_position.y < -EXIT_MARGIN or global_position.y > screen_size.y + EXIT_MARGIN:
		if trail_points.size() > 4:
			# Wait until tail mostly clears or check deeper margin
			if global_position.x < -EXIT_MARGIN * 1.5 or global_position.x > screen_size.x + EXIT_MARGIN * 1.5 \
			or global_position.y < -EXIT_MARGIN * 1.5 or global_position.y > screen_size.y + EXIT_MARGIN * 1.5:
				queue_free()
				return
		else:
			queue_free()
			return
			
	queue_redraw()

func _draw():
	# Draw icy tail in local space
	if trail_points.size() >= 2:
		for i in range(trail_points.size() - 1):
			var t: float = 1.0 - (float(i) / float(trail_points.size()))
			var p1: Vector2 = to_local(trail_points[i])
			var p2: Vector2 = to_local(trail_points[i + 1])
			draw_line(p1, p2, Color(COLOR_TAIL.r, COLOR_TAIL.g, COLOR_TAIL.b, t * 0.55), t * 14.0)
			draw_line(p1, p2, Color(1.0, 1.0, 1.0, t * 0.75), t * 4.5)
			
	# Draw icy debris sparks
	for s in debris_sparks:
		var alpha: float = clamp(s["life"] / s["max_life"], 0.0, 1.0)
		var lp: Vector2 = to_local(s["pos"])
		draw_circle(lp, 1.8 * alpha + 0.5, Color(0.75, 0.96, 1.0, alpha * 0.85))
		
	# Draw jagged crystalline comet nucleus
	var core_col: Color = Color.WHITE if flash_time > 0.0 else COLOR_ICE_CORE
	var glow_col: Color = Color.WHITE if flash_time > 0.0 else COLOR_ICE_GLOW
	var pts := PackedVector2Array()
	var num_pts := 7
	for i in range(num_pts):
		var ang: float = spin_angle + (float(i) / float(num_pts)) * TAU
		var r: float = 16.0 if i % 2 == 0 else 10.5
		pts.append(Vector2(cos(ang), sin(ang)) * r)
	pts.append(pts[0])
	
	draw_circle(Vector2.ZERO, 13.0, Color(glow_col.r, glow_col.g, glow_col.b, 0.28))
	draw_polyline(pts, Color(glow_col.r, glow_col.g, glow_col.b, 0.45), 5.0)
	draw_polyline(pts, core_col, 2.2)

func take_damage(amount: int = 1):
	health -= amount
	flash_time = 0.08
	if health <= 0:
		_shatter(true)

func takeDamange():
	take_damage(1)

func _shatter(award_player: bool):
	if is_queued_for_deletion():
		return
	var parent_node := get_parent()
	if parent_node != null:
		if award_player:
			var sm = get_tree().get_first_node_in_group("score_manager")
			if sm != null:
				sm.add_score(score_value, global_position)
			var pu = powerup_scene.instantiate()
			pu.global_position = global_position
			parent_node.call_deferred("add_child", pu)
			
		var shrapnel = load("res://effects/vector_shrapnel.gd")
		if shrapnel != null:
			shrapnel.spawn(parent_node, global_position, COLOR_ICE_GLOW, 12, 1.5)
			
		var am = load("res://scripts/audio_manager.gd")
		if am != null:
			am.play_explosion(get_tree(), false)
			
		var cam_shake = load("res://scripts/camera_shake.gd")
		if cam_shake != null:
			cam_shake.shake(get_tree(), 0.35)
			
		var impact_fx = load("res://effects/impact_fx.gd")
		if impact_fx != null:
			impact_fx.spawn_comet_shatter(parent_node, global_position)
			
	shattered.emit(global_position)
	queue_free()

