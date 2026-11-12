extends CharacterBody2D

signal hit(pos)
signal destroyed

@onready var screen_size = get_viewport_rect().size

@onready var collisionShape = $CollisionShape2D

@export var lifetime := 1.25
@export var damage := 1

var time_alive := 0.0

func _draw():
	draw_circle(Vector2(0,0), 3.0, Color.WHITE)

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
		hit.emit(position)
		destroyed.emit()
		queue_free()
