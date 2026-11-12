extends CharacterBody2D

signal destroyed(pos: Vector2)

@export var max_health: int = 1
@export var speed: float = 85.0
@export var turn_speed: float = 2.2

var health: int = 1
var flash_time: float = 0.0
var thruster_flicker: float = 0.0

var rock_crash_scene = preload("res://effects/rock_crash.tscn")
var powerup_scene = preload("res://Pickups/powerup.tscn")

@onready var screen_size: Vector2 = get_viewport_rect().size

# Visual Colors
const COLOR_DRONE: Color = Color(1.0, 0.55, 0.0)      # Warning Amber/Orange
const COLOR_THRUST: Color = Color(1.0, 0.9, 0.2)     # Thruster Yellow

func _ready():
	add_to_group("enemies")
	add_to_group("drones")
	health = max_health

func _process(delta: float):
	thruster_flicker += delta * 20.0
	if flash_time > 0.0:
		flash_time -= delta
	queue_redraw()

func _physics_process(delta: float):
	var parent_node = get_parent()
	if parent_node != null:
		var player = parent_node.get_node_or_null("player")
		if player != null and !player.is_dead:
			# Steer towards player
			var target_dir = (player.global_position - global_position).normalized()
			var current_dir = Vector2(0, -1).rotated(rotation)
			var angle_to_target = current_dir.angle_to(target_dir)
			
			rotation += clamp(angle_to_target, -turn_speed * delta, turn_speed * delta)
			velocity = Vector2(0, -1).rotated(rotation) * speed
		else:
			# Drift forward if no player
			velocity = Vector2(0, -1).rotated(rotation) * (speed * 0.5)
	
	move_and_slide()
	
	# Wrap screen
	position.x = wrapf(position.x, 0.0, screen_size.x)
	position.y = wrapf(position.y, 0.0, screen_size.y)
	
	# Check collision with player or asteroids
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider != null:
			if collider.name == "player":
				collider.take_damage(1)
				destroy(false)
				return
			elif collider.is_in_group("asteroids") or collider.name.begins_with("asteroid") or collider is RigidBody2D:
				destroy(true)
				return

func take_damage(amount: int = 1):
	health -= amount
	flash_time = 0.1
	if health <= 0:
		destroy(true)

func takeDamange():
	take_damage(1)

func take_damange():
	take_damage(1)

func destroy(drop_powerup_chance: bool = true):
	var parent_node = get_parent()
	if parent_node != null:
		var sm = get_tree().get_first_node_in_group("score_manager")
		if sm != null:
			sm.add_score(250, global_position)
			
		var crash = rock_crash_scene.instantiate()
		crash.global_position = global_position
		var emitter = crash.get_child(0)
		emitter.amount = 30
		emitter.lifetime = 1.0
		emitter.color = COLOR_DRONE
		parent_node.add_child(crash)
		emitter.emitting = true
		
		var shrapnel = load("res://effects/vector_shrapnel.gd")
		if shrapnel != null:
			shrapnel.spawn(parent_node, global_position, COLOR_DRONE, 7, 1.1)
		var cam_shake = load("res://scripts/camera_shake.gd")
		if cam_shake != null:
			cam_shake.shake(get_tree(), 0.30)
		
		# 30% chance to drop powerup if shot
		if drop_powerup_chance and randf() < 0.30:
			var pu = powerup_scene.instantiate()
			pu.global_position = global_position
			pu.type = randi() % 4
			parent_node.add_child(pu)
			
	destroyed.emit(global_position)
	queue_free()

func _draw():
	var col: Color = Color.WHITE if flash_time > 0.0 else COLOR_DRONE
	
	# Aggressive vector dart interceptor
	var pts: PackedVector2Array = [
		Vector2(0, -14),
		Vector2(8, 8),
		Vector2(3, 4),
		Vector2(-3, 4),
		Vector2(-8, 8),
		Vector2(0, -14)
	]
	draw_polyline(pts, col, 2.0)
	
	# Inner canopy eye
	draw_line(Vector2(0, -10), Vector2(0, -2), col, 1.5)
	
	# Thruster exhaust flame
	if sin(thruster_flicker) > 0.0:
		var flame_pts: PackedVector2Array = [
			Vector2(-3, 5),
			Vector2(0, 11 + randf_range(-1.5, 1.5)),
			Vector2(3, 5)
		]
		draw_polyline(flame_pts, COLOR_THRUST, 1.5)

