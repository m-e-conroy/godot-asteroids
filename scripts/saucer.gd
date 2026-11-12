extends CharacterBody2D

signal destroyed(pos: Vector2)
signal fired_bullet(pos: Vector2, dir: Vector2)

@export var level: int = 1
@export var max_health: int = 3
@export var horizontal_speed: float = 70.0

var health: int = 3
var direction: float = 1.0 # 1.0 = left-to-right, -1.0 = right-to-left
var bob_time: float = 0.0
var fire_timer: float = 0.0
var deploy_timer: float = 0.0
var flash_time: float = 0.0

var powerup_scene = preload("res://Pickups/powerup.tscn")
var bullet_scene = preload("res://Enemies/Saucer/saucer_bullet.tscn")
var rock_crash_scene = preload("res://effects/rock_crash.tscn")
var explosion_sound = preload("res://sounds/explosion.wav")

# Sub-enemy preloads (will be instantiated in higher waves)
var probe_scene: PackedScene = null
var drone_scene: PackedScene = null

@onready var screen_size: Vector2 = get_viewport_rect().size

# Visual Colors
const COLOR_HULL: Color = Color(1.0, 0.15, 0.4)       # Neon Red/Magenta
const COLOR_CANOPY: Color = Color(1.0, 0.85, 0.2)     # Neon Yellow
const COLOR_POD: Color = Color(0.3, 0.85, 1.0)        # Underbelly Cyan

func _ready():
	add_to_group("enemies")
	add_to_group("saucers")
	health = max_health
	
	# Connect HitArea for incoming asteroid collisions
	if has_node("HitArea"):
		$HitArea.connect("body_entered", _on_hit_area_body_entered)
	
	# Load sub-enemy scenes dynamically if available
	if ResourceLoader.exists("res://Enemies/Probe/probe.tscn"):
		probe_scene = load("res://Enemies/Probe/probe.tscn")
	if ResourceLoader.exists("res://Enemies/Drone/drone.tscn"):
		drone_scene = load("res://Enemies/Drone/drone.tscn")
		
	# Randomize starting horizontal direction and vertical position if not set
	if direction == 0.0:
		direction = 1.0 if randf() > 0.5 else -1.0
	
	# Fire timer based on level
	fire_timer = get_fire_interval()
	deploy_timer = 5.0

func get_fire_interval() -> float:
	# Scales from 3.5s at wave 1 down to 1.2s at wave 8+
	return max(1.2, 3.5 - (level - 1) * 0.3)

func _process(delta: float):
	if flash_time > 0.0:
		flash_time -= delta
	queue_redraw()

func _physics_process(delta: float):
	bob_time += delta * 1.5
	
	# Compute intelligent vertical asteroid avoidance
	var avoid_y: float = _compute_asteroid_avoidance()
	var target_vy: float = sin(bob_time) * 28.0 + (avoid_y * 110.0)
	
	velocity.x = direction * horizontal_speed
	velocity.y = move_toward(velocity.y, target_vy, 150.0 * delta)
	
	move_and_slide()
	
	# Wrap screen horizontally and clamp vertically within playfield
	position.x = wrapf(position.x, 0.0, screen_size.x)
	position.y = wrapf(position.y, 40.0, screen_size.y - 40.0)
	
	# Check slide collisions with player or asteroids
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider != null:
			if collider.name == "player":
				if collider.has_method("take_damage"):
					collider.take_damage(1)
			elif collider.is_in_group("asteroids") or collider.name.begins_with("asteroid") or collider is RigidBody2D:
				# Collided with an asteroid -> explode!
				if collider.has_method("take_damage"):
					collider.take_damage(2)
				destroy()
				return
	
	# Aim and shoot at player
	fire_timer -= delta
	if fire_timer <= 0.0:
		_shoot_at_player()
		fire_timer = get_fire_interval()
		
	# Deploy sub-enemies at higher waves
	if level >= 2:
		deploy_timer -= delta
		if deploy_timer <= 0.0:
			_deploy_sub_enemy()
			deploy_timer = randf_range(8.0, 14.0)

func _compute_asteroid_avoidance() -> float:
	var avoid_force_y: float = 0.0
	
	for asteroid in get_tree().get_nodes_in_group("asteroids"):
		if !is_instance_valid(asteroid) or asteroid.is_queued_for_deletion():
			continue
			
		var offset: Vector2 = asteroid.global_position - global_position
		# Check if asteroid is in the forward cruising path of the saucer
		var forward_dist: float = offset.x * direction
		if forward_dist > 0.0 and forward_dist < 200.0:
			var ast_radius: float = asteroid.radius if "radius" in asteroid else 60.0
			var danger_zone_y: float = ast_radius + 45.0
			if abs(offset.y) < danger_zone_y:
				var closeness: float = 1.0 - (forward_dist / 200.0)
				# If asteroid is below or at same level, steer up; if above, steer down
				if offset.y >= 0.0:
					avoid_force_y -= closeness * 1.5
				else:
					avoid_force_y += closeness * 1.5
					
	# Soft edge repulsion from top and bottom screen margins
	if position.y < 90.0:
		avoid_force_y += 1.2
	elif position.y > screen_size.y - 90.0:
		avoid_force_y -= 1.2
		
	return clamp(avoid_force_y, -1.8, 1.8)

func _on_hit_area_body_entered(body: Node2D):
	if is_queued_for_deletion():
		return
	if body.is_in_group("asteroids") or body.name.begins_with("asteroid") or body is RigidBody2D:
		if body.has_method("take_damage"):
			body.take_damage(2)
		destroy()

func _shoot_at_player():
	var parent_node = get_parent()
	if parent_node == null:
		return
	var player = parent_node.get_node_or_null("player")
	if player == null or player.is_dead:
		return
		
	# Calculate aim direction towards player with level-based accuracy
	var target_pos: Vector2 = player.global_position
	var aim_dir: Vector2 = (target_pos - global_position).normalized()
	
	# Lower levels have some inaccuracy; higher levels are deadly accurate
	var inaccuracy_angle: float = max(0.02, 0.35 - (level * 0.04))
	aim_dir = aim_dir.rotated(randf_range(-inaccuracy_angle, inaccuracy_angle))
	
	var b = bullet_scene.instantiate()
	b.global_position = global_position + aim_dir * 18.0
	b.velocity = aim_dir * b.speed
	b.rotation = aim_dir.angle()
	b.add_collision_exception_with(self)
	parent_node.add_child(b)
	fired_bullet.emit(global_position, aim_dir)

func _deploy_sub_enemy():
	var parent_node = get_parent()
	if parent_node == null:
		return
		
	if level >= 3 and drone_scene != null and randf() > 0.4:
		# Launch Hunter Drone
		var drone = drone_scene.instantiate()
		drone.global_position = global_position + Vector2(0, 15)
		parent_node.add_child(drone)
	elif probe_scene != null:
		# Drop Sentry Probe mine
		var probe = probe_scene.instantiate()
		probe.global_position = global_position + Vector2(0, 15)
		parent_node.add_child(probe)

func take_damage(amount: int = 1):
	health -= amount
	flash_time = 0.12
	if health <= 0:
		destroy()

func takeDamange():
	take_damage(1)

func take_damange():
	take_damage(1)

func destroy():
	if is_queued_for_deletion():
		return
		
	var parent_node = get_parent()
	if parent_node != null:
		var sm = get_tree().get_first_node_in_group("score_manager")
		if sm != null:
			sm.add_score(300, global_position)
			
		# Play synthesized arcade explosion audio
		var am = load("res://scripts/audio_manager.gd")
		if am != null:
			am.play_explosion(get_tree(), true)
		
		# Spawn particle crash explosion
		var crash = rock_crash_scene.instantiate()
		crash.global_position = global_position
		var emitter = crash.get_child(0)
		emitter.amount = 40
		emitter.lifetime = 1.2
		emitter.color = COLOR_HULL
		parent_node.add_child(crash)
		emitter.emitting = true
		
		var shrapnel = load("res://effects/vector_shrapnel.gd")
		if shrapnel != null:
			shrapnel.spawn(parent_node, global_position, COLOR_HULL, 9, 1.3)
		var cam_shake = load("res://scripts/camera_shake.gd")
		if cam_shake != null:
			cam_shake.shake(get_tree(), 0.45)
		
		# Drop random wireframe powerup
		var pu = powerup_scene.instantiate()
		pu.global_position = global_position
		# Random type between 0 and 3
		pu.type = randi() % 4
		parent_node.add_child(pu)
	
	destroyed.emit(global_position)
	queue_free()

func _draw():
	var hull_col: Color = Color.WHITE if flash_time > 0.0 else COLOR_HULL
	var canopy_col: Color = Color.WHITE if flash_time > 0.0 else COLOR_CANOPY
	var pod_col: Color = Color.WHITE if flash_time > 0.0 else COLOR_POD
	
	# 1. Main outer saucer rim
	var hull_pts: PackedVector2Array = [
		Vector2(-24, 0),
		Vector2(-16, -6),
		Vector2(16, -6),
		Vector2(24, 0),
		Vector2(16, 6),
		Vector2(-16, 6),
		Vector2(-24, 0)
	]
	draw_polyline(hull_pts, hull_col, 2.0)
	
	# 2. Midline equator
	draw_line(Vector2(-24, 0), Vector2(24, 0), hull_col, 1.5)
	
	# 3. Cockpit canopy dome
	var canopy_pts: PackedVector2Array = [
		Vector2(-10, -6),
		Vector2(-6, -14),
		Vector2(6, -14),
		Vector2(10, -6)
	]
	draw_polyline(canopy_pts, canopy_col, 2.0)
	# Canopy interior pilot pip
	draw_circle(Vector2(0, -9), 2.0, canopy_col)
	
	# 4. Underbelly emitter / landing pod
	var pod_pts: PackedVector2Array = [
		Vector2(-8, 6),
		Vector2(-5, 11),
		Vector2(5, 11),
		Vector2(8, 6)
	]
	draw_polyline(pod_pts, pod_col, 1.5)
