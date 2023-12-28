extends Sprite2D

var polyPts := []
var colr: Color = Color.BLACK

func _draw():
	if polyPts.size() > 0:
		draw_shape(polyPts, get_parent().color, Color.BLACK)
		#draw_colored_polygon(PackedVector2Array($"..".polyPts), Color.BLACK)
		#draw_polyline(PackedVector2Array($"..".polyPts), $"..".color, 2.0)
		
func draw_shape(pts, outline, fill):
	draw_colored_polygon(PackedVector2Array(pts), fill)
	draw_polyline(PackedVector2Array(pts), outline, 2.0)
	
# Called when the node enters the scene tree for the first time.
func _ready():
	polyPts = get_parent().polyPts
	colr = get_parent().color

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	queue_redraw()
