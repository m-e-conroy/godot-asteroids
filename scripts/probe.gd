extends CharacterBody2D

signal destroyed(pos: Vector2)

@export var max_health: int = 1
@export var drift_speed: float = 35.0
@export var detonation_radius: float = 40.0

var health: int = 1
var rotation_speed: float = 1.8
var pulse_time: float = 0.0
var flash_time: float = 0.0

var rock_crash_scene = preload("res://effects/rock_crash.tscn")
var powerup_scene = preload("res://Pickups/powerup.tscn")

@onready var screen_size: Vector2 = get_viewport_rect().size

# Visual Colors
const COLOR_AMETHYST: Color = Color(0.8, 0.3, 1.0)
const COLOR_CORE: Color = Color(1.0, 0.5, 1.0)

func _ready():
	add_to_group("enemies")
	add_to_group("probes")
	health = max_health
	
	# Random drift velocity
	var angle = randf() * 2.0 * PI
	velocity = Vector2(cos(angle), sin(angle)) * drift_speed

func _process(delta: float):
	rotation += rotation_speed * delta
	pulse_time += delta * 4.0
	if flash_time > 0.0:
		flash_time -= delta
	queue_redraw()

func _physics_process(delta: float):
	move_and_slide()
	
	# Wrap screen
	position.x = wrapf(position.x, 0.0, screen_size.x)
	position.y = wrapf(position.y, 0.0, screen_size.y)
	
	# Check proximity to player
	var parent_node = get_parent()
	if parent_node != null:
		var player = parent_node.get_node_or_null("player")
		if player != null and !player.is_dead:
			var dist = global_position.distance_to(player.global_position)
			if dist <= detonation_radius:
				player.take_damage(1)
				destroy(false)
				return
				
	# Check collision with bodies
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider != null and collider.name == "player":
			collider.take_damage(1)
			destroy(false)
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
			sm.add_score(150)
			
		var crash = rock_crash_scene.instantiate()
		crash.global_position = global_position
		var emitter = crash.get_child(0)
		emitter.amount = 25
		emitter.lifetime = 0.8
		emitter.color = COLOR_AMETHYST
		parent_node.add_child(crash)
		emitter.emitting = true
		
		# 25% chance to drop powerup if shot
		if drop_powerup_chance and randf() < 0.25:
			var pu = powerup_scene.instantiate()
			pu.global_position = global_position
			pu.type = randi() % 4
			parent_node.add_child(pu)
			
	destroyed.emit(global_position)
	queue_free()

func _draw():
	var col: Color = Color.WHITE if flash_time > 0.0 else COLOR_AMETHYST
	var s: float = 1.0 + sin(pulse_time) * 0.1
	
	# Octagonal / 8-pointed star wireframe mine
	var pts: PackedVector2Array = [
		Vector2(0, -12 * s),
		Vector2(4 * s, -4 * s),
		Vector2(12 * s, 0),
		Vector2(4 * s, 4 * s),
		Vector2(0, 12 * s),
		Vector2(-4 * s, 4 * s),
		Vector2(-12 * s, 0),
		Vector2(-4 * s, -4 * s),
		Vector2(0, -12 * s)
	]
	draw_polyline(pts, col, 2.0)
	
	# Concentric inner diamond
	var inner_pts: PackedVector2Array = [
		Vector2(0, -6 * s),
		Vector2(6 * s, 0),
		Vector2(0, 6 * s),
		Vector2(-6 * s, 0),
		Vector2(0, -6 * s)
	]
	draw_polyline(inner_pts, COLOR_CORE, 1.5)
	
	# Glowing center core
	draw_circle(Vector2.ZERO, 2.5 * s, Color.WHITE)

