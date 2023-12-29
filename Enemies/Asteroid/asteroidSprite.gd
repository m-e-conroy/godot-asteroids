extends Sprite2D

@onready var PARENT := get_parent()

var minPts := 15
var maxPts := 25
var minRadius := 80.0
var radius := 100.0
var fillColor: Color = Color.BLACK
var polyPts: Array = []

var rnd = RandomNumberGenerator.new()
	
func _ready():
	rnd.randomize()
	if !PARENT.CLONED:
		match PARENT.SIZE:
			'lg':
				minPts = 15
				maxPts = 25
				minRadius = 80.0
				radius = 100.0
			'md':
				minPts = 10
				maxPts = 20
				minRadius = 55.0
				radius = 75.0
			'sm':
				minPts = 6
				maxPts = 14
				minRadius = 20.0
				radius = 30.0
			'xs':
				minPts = 3
				maxPts = 8
				minRadius = 6.0
				radius = 12.0
		# match

		if polyPts.size() <= 0:
			# create a random number of points
			var numPts = rnd.randi_range(minPts, maxPts)
			
			# number of radians apart each point of the asteroid will be
			var radiansPerSection: float = (2 * PI) / numPts
			
			for i in numPts:
				# angle in radians
				var angle: float = (i * radiansPerSection)
				
				# randomize the distance from center
				var h: float = rnd.randf_range(minRadius, radius)
				# determine x,y coords
				var x: float = cos(angle) * h
				var y: float = sin(angle) * h
				
				# add point to the array of points that will make our shape
				polyPts.push_back(Vector2(x, y))
			# end for
			
			# complete the polygon by adding the first to the last
			polyPts.push_back(polyPts[0])
		# end if
# _ready

func _draw():
	if polyPts.size() > 0:
		draw_shape(polyPts, PARENT.COLOR, fillColor)
# _draw
		
func draw_shape(pts, outline, fill):
	draw_colored_polygon(PackedVector2Array(pts), fill)
	draw_polyline(PackedVector2Array(pts), outline, 2.0)
# draw_shape

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	queue_redraw()
# _process
