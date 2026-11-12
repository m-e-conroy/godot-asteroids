extends CharacterBody2D

signal hit(pos: Vector2)
signal destroyed

@export var speed: float = 340.0
@export var lifetime: float = 2.2
@export var damage: int = 1

var time_alive: float = 0.0
const COLOR_LASER: Color = Color(1.0, 0.2, 0.35)

@onready var screen_size: Vector2 = get_viewport_rect().size

func _ready():
	add_to_group("enemy_bullets")

func _process(_delta: float):
	queue_redraw()

func _physics_process(delta: float):
	time_alive += delta
	if time_alive >= lifetime:
		destroy()
		return
		
	# Screen wrap
	position.x = wrapf(position.x, 0.0, screen_size.x)
	position.y = wrapf(position.y, 0.0, screen_size.y)
	
	var collision = move_and_collide(velocity * delta)
	if collision:
		var target = collision.get_collider()
		if target != null:
			if target.name == "player" or target.has_method("take_damage"):
				target.take_damage(damage)
			elif target.has_method("takeDamange"):
				target.takeDamange()
		hit.emit(global_position)
		destroy()

func destroy():
	destroyed.emit()
	queue_free()

func _draw():
	# Elongated vector energy capsule
	var dir_norm = velocity.normalized()
	var perp = Vector2(-dir_norm.y, dir_norm.x)
	
	var p1 = dir_norm * 6.0
	var p2 = -dir_norm * 6.0
	var p3 = perp * 2.5
	var p4 = -perp * 2.5
	
	var pts: PackedVector2Array = [p1, p3, p2, p4, p1]
	draw_polyline(pts, COLOR_LASER, 2.0)
	draw_circle(Vector2.ZERO, 2.0, Color.WHITE)
