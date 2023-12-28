extends CharacterBody2D

signal hit(pos)

@onready var screen_size = get_viewport_rect().size

@onready var collisionShape = $CollisionShape2D

var damage := 10

func _draw():
	draw_circle(Vector2(0,0), 3.0, Color.WHITE)

# Called when the node enters the scene tree for the first time.
func _ready():
	var circle = CircleShape2D.new()
	circle.radius = 3.0
	collisionShape.shape = circle
	collisionShape.debug_color = Color.WHITE

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	queue_redraw()

func _physics_process(delta):
	# wrap screen around to the other side if the player or object should fall out of bounds of the window
	position.x = wrapf(position.x, 0, screen_size.x)
	position.y = wrapf(position.y, 0, screen_size.y)
	
	var collision = move_and_collide(velocity * delta)
	if collision:
		var obj = collision.get_collider()
		if obj.has_method("take_damange"):
			obj.take_damange()
		hit.emit(position)
		queue_free()
