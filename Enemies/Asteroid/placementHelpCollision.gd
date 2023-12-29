extends CollisionPolygon2D

@onready var SPRITE := $"../../Sprite2D"

# Called when the node enters the scene tree for the first time.
func _ready():
	set_polygon(SPRITE.polyPts)
	set_one_way_collision_margin(2.0)
