extends CharacterBody2D

signal hit(pos)
signal destroyed

@onready var screen_size = get_viewport_rect().size

@onready var collisionShape = $CollisionShape2D

@export var lifetime := 1.25
@export var damage := 1

var time_alive := 0.0

func _draw():
	# Outer phosphor laser halo & tail
	draw_line(Vector2(0, -3), Vector2(0, 18), Color(0.16, 0.94, 0.25, 0.45), 4.0)
	# Crisp inner laser bolt
	draw_line(Vector2(0, -4), Vector2(0, 12), Color(0.88, 1.0, 0.92, 0.95), 1.8)
	draw_circle(Vector2(0, -2), 2.6, Color.WHITE)

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("player_bullets")
	var circle = CircleShape2D.new()
	circle.radius = 3.0
	collisionShape.shape = circle
	collisionShape.debug_color = Color.WHITE

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	queue_redraw()

func _physics_process(delta):
	time_alive += delta
	if time_alive >= lifetime:
		destroyed.emit()
		queue_free()
		return

	# wrap screen around to the other side if the player or object should fall out of bounds of the window
	position.x = wrapf(position.x, 0, screen_size.x)
	position.y = wrapf(position.y, 0, screen_size.y)
	
	var collision = move_and_collide(velocity * delta)
	if collision:
		var obj = collision.get_collider()
		if obj == null or obj.name == "player" or obj.is_in_group("player") or obj.is_in_group("player_bullets"):
			return
		if obj.has_method("take_damage"):
			obj.take_damage(damage)
		elif obj.has_method("takeDamange"):
			obj.takeDamange()
		elif obj.has_method("take_damange"):
			obj.take_damange()
		var hit_normal: Vector2 = collision.get_normal()
		if hit_normal == Vector2.ZERO and velocity.length_squared() > 0.001:
			hit_normal = -velocity.normalized()
		var spark_col := Color(0.45, 1.0, 0.55)
		if obj.is_in_group("comets"):
			spark_col = Color(0.55, 0.95, 1.0)
		elif "COLOR" in obj:
			spark_col = obj.COLOR
		var impact_fx = load("res://effects/impact_fx.gd")
		if impact_fx != null:
			impact_fx.spawn_ricochet(get_parent(), collision.get_position(), hit_normal, spark_col)
		hit.emit(position)
		destroyed.emit()
		queue_free()
