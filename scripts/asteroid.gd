extends CharacterBody2D

signal destroyed(pos, size)

@onready var screen_size = get_viewport_rect().size

@onready var collisionShape = $CollisionPolygon2D

var size = "large"

var minNumberPts := 20
var maxNumberPts := 40
var polyPts: Array = []
var radius := 150
var minRadius := 90
var startVelocity := Vector2(1,1)
var rotation_speed := 0.0
var mass := 0.0

var c: Color = Color.LAWN_GREEN
var strength: int = 1
var rnd = RandomNumberGenerator.new()
	
func _ready():
	rnd.randomize()
	# determine parameters by the size of the asteroid desired
	match size:
		'large':
			minNumberPts = 15
			maxNumberPts = 25
			minRadius = 75
			radius = 100
			startVelocity = Vector2(rnd.randi_range(4,16) * randomPosNegOne(), rnd.randi_range(4,16) * randomPosNegOne())
			mass = rnd.randf_range(.8, 1)
			strength = rnd.randi_range(3, 6)
		'medium':
			minNumberPts = 10
			maxNumberPts = 20
			minRadius = 50
			radius = 75
			startVelocity = Vector2(rnd.randi_range(-20,20) * randomPosNegOne(), rnd.randi_range(-20,20) * randomPosNegOne())
			mass = rnd.randf_range(.4, .6)
			strength = rnd.randi_range(2, 4)
		'small':
			minNumberPts = 6
			maxNumberPts = 14
			minRadius = 20
			radius = 30
			startVelocity = Vector2(rnd.randi_range(-40,40) * randomPosNegOne(), rnd.randi_range(-40,40) * randomPosNegOne())
			mass = rnd.randf_range(.1, .3)
			strength = rnd.randi_range(1, 3)
	# determine all points of the asteroid shape
	if polyPts.size() <= 0:
		# create a random number of points
		var numPts = rnd.randi_range(minNumberPts, maxNumberPts)
		
		# generate the random point coordinates
		var degreesPerSection: int = 360 / numPts
		
		for i in numPts:
			# angle in radians
			var angle = (i * degreesPerSection) * PI / 180
			
			var h = rnd.randi_range(minRadius, radius)
			var x = cos(angle) * h
			var y = sin(angle) * h
			
			polyPts.push_back(Vector2(x, y))
		# end for
		
		# compolete the polygon by adding the first to the last
		polyPts.push_back(polyPts[0])
	# end if
	
	collisionShape.set_polygon(polyPts)
	# setup random position, velocity
	position = Vector2(rnd.randi_range(0, screen_size.x), rnd.randi_range(0, screen_size.y))
	rotation_speed = randomPosNegOne() * randf_range(0.1, .3)
	velocity = startVelocity
	
func _process(_delta):
	pass
	
func _physics_process(delta):
	position.x = wrapf(position.x, 0, screen_size.x)
	position.y = wrapf(position.y, 0, screen_size.y)
	rotation += delta * rotation_speed
	
	var collision = move_and_collide(velocity * delta)
	if collision:
		var collider = collision.get_collider()
		if collider.mass > 0:
			velocity = (((mass - collider.mass) / (mass + collider.mass)) * velocity) + (((2 * collider.mass) / (mass + collider.mass)) * collider.velocity)
			# collider.velocity = (((2 * mass) / (mass + collider.mass)) * velocity) + (((collider.mass - mass) / (mass + collider.mass)) * collider.velocity)
			
			#rotation = (((mass - collider.mass) / (mass + collider.mass)) * rotation) + (((2 * collider.mass) / (mass + collider.mass)) * collider.rotation)
			#collider.rotation = (((2 * mass) / (mass + collider.mass)) * rotation) + (((collider.mass - mass) / (mass + collider.mass)) * collider.rotation)
			# collider.rotation
		
func init(sz):
	size = sz
	
func randomPosNegOne():
	var one = rnd.randf_range(-1,1)
	if one < 0:
		return -1
	else:
		return 1
		
func normalize(val, min, max):
	return (val - min) / (max - min)
	
func take_damange():
	strength -= 1
	if strength < 0:
		# emit signal and remove asteroid
		destroyed.emit(global_position, size)
