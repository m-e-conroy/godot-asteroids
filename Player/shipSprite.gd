extends Sprite2D

@onready var PARENT := get_parent()

# drawing shapes
const SHIP_SHAPE: Array = [Vector2(0,-15), Vector2(7,10), Vector2(0,5), Vector2(-7,10), Vector2(0,-15)]
const RT_THRUSTER_SHAPE: Array = [Vector2(5,-10), Vector2(15,-12), Vector2(4,-14), Vector2(5,-10)]
const LT_THRUSTER_SHAPE: Array = [Vector2(-5,-10), Vector2(-15,-12), Vector2(-4,-14), Vector2(-5,-10)]
const THRUSTER_SHAPE: Array = [Vector2(3,11), Vector2(0,30), Vector2(-3,11), Vector2(3,11)]

@export_group('Ship Graphic Parameters')
@export var SHIELD_RADIUS := 40.0
@export var SHIELD_COLOR: Color = Color.DIM_GRAY
@export var SHIP_COLOR: Color = Color.LAWN_GREEN

var shieldStrengthIndicatorColor: Color = Color.LAWN_GREEN
var shieldStrengthIndicatorAngle := 360.0

var thrusterColorGradient: PackedColorArray = PackedColorArray([Color.DIM_GRAY, Color.BLACK, Color.DIM_GRAY, Color.DIM_GRAY])

func _draw():
	# determine shield indicator color and angle length
	if PARENT.SHIELD_STRENGTH > 60.0:
		shieldStrengthIndicatorColor = Color.LAWN_GREEN
	elif PARENT.SHIELD_STRENGTH > 20.0:
		shieldStrengthIndicatorColor = Color.YELLOW
	else:
		shieldStrengthIndicatorColor = Color.RED
		
	shieldStrengthIndicatorAngle = ((2 * PI) * PARENT.SHIELD_STRENGTH) / 100.0
	
	# draw the ship
	draw_polyline(PackedVector2Array(SHIP_SHAPE), SHIP_COLOR, 2.0)
		
	# draw thrusters when parent variable is true for that thruster
	if PARENT.TURN_LEFT:
		draw_polygon(PackedVector2Array(RT_THRUSTER_SHAPE), thrusterColorGradient)
	if PARENT.TURN_RIGHT:
		draw_polygon(PackedVector2Array(LT_THRUSTER_SHAPE), thrusterColorGradient)
	if PARENT.THRUST:
		draw_polygon(PackedVector2Array(THRUSTER_SHAPE), thrusterColorGradient)
	if PARENT.SHIELD && !(PARENT.SHIELD_STRENGTH <= 0):
		draw_arc(Vector2(0,0), SHIELD_RADIUS + 3.0, 0.0, 2 * PI, 36, SHIELD_COLOR, 2.0)
		draw_arc(Vector2(0,0), SHIELD_RADIUS - 2.0, 0.0, shieldStrengthIndicatorAngle, 36, shieldStrengthIndicatorColor, 1.5)
	
func _process(_delta):
	queue_redraw() # calls _draw again, needed for thrusters
