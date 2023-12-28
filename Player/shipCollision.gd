extends CollisionPolygon2D

@onready var SPRITE: Sprite2D = $"../Sprite2D"

# drawing shapes
const SHIP_COLLISION_SHAPE: Array = [Vector2(0,-16), Vector2(8,11), Vector2(0,6), Vector2(-8,11), Vector2(0,-16)]

# Called when the node enters the scene tree for the first time.
func _ready():
	if SPRITE.SHIP_SHAPE:
		set_polygon(SPRITE.SHIP_SHAPE)
	else:
		set_polygon(SHIP_COLLISION_SHAPE)
	# if
	set_one_way_collision_margin(2.0)
# _ready
