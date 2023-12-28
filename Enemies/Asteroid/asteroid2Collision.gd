extends CollisionPolygon2D

var polyPts: Array = []

func _draw():
	if polyPts.size() > 0:
		draw_colored_polygon(PackedVector2Array(polyPts), Color.RED)
	
# Called when the node enters the scene tree for the first time.
func _ready():
	polyPts = get_parent().polyPts
