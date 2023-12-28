extends CollisionPolygon2D

# drawing shapes
const SHIP_COLLISION_SHAPE: Array = [Vector2(0,-16), Vector2(8,11), Vector2(0,6), Vector2(-8,11), Vector2(0,-16)]

# Called when the node enters the scene tree for the first time.
func _ready():
	set_polygon(SHIP_COLLISION_SHAPE)
