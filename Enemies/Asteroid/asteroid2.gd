extends RigidBody2D

signal destroyed(pos, sz)
signal linear_velocity_changed(vec)
signal angular_velocity_changed(rad)
signal take_hit

var rock_crash = preload("res://effects/rock_crash.tscn")

@onready var sprite := $Sprite2D
@onready var collisionShape := $CollisionPolygon2D
@onready var placementHelpArea := $Area2D
@onready var screen_size = get_viewport_rect().size

var size: String = 'lg'
var strength: int = 1
var color: Color = Color.LAWN_GREEN

var minPts := 20
var maxPts := 40
var polyPts: Array = []
var radius := 100
var minRadius := 75
var lv: Vector2 = Vector2.ZERO
var av: float = 0.0

var clones: Dictionary = {
	"top": null,
	"bottom": null,
	"left": null,
	"right": null,
	"corner": null
}
var cloned: bool = false

var rnd = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	rnd.randomize()
	
	linear_damp = 0 # how much linear movement slows down by in open space (friction)
	angular_damp = 0 # how much rotational movement slows down by in open space (friction)
	gravity_scale = 0
	contact_monitor = true # turn on collision detection
	max_contacts_reported = 10
	
	match size:
		'lg':
			minPts = 15
			maxPts = 25
			minRadius = 80
			radius = 100
			mass = rnd.randi_range(150, 200)
			strength = rnd.randi_range(12,18)
		'md':
			minPts = 10
			maxPts = 20
			minRadius = 55
			radius = 75
			mass = rnd.randi_range(80, 130)
			strength = rnd.randi_range(5,10)
		'sm':
			minPts = 6
			maxPts = 14
			minRadius = 20
			radius = 30
			mass = rnd.randi_range(10, 60)
			strength = rnd.randi_range(1,3)
			
	if polyPts.size() <= 0:
		# create a random number of points
		var numPts = rnd.randi_range(minPts, maxPts)
		
		# generate the random point coordinates
		var degreesPerSection: int = 360 / numPts
		
		for i in numPts:
			# angle in radians
			var angle = (i * degreesPerSection) * PI / 180
			
			# randomize the distance from center
			var h = rnd.randi_range(minRadius, radius)
			# determine x,y coords
			var x = cos(angle) * h
			var y = sin(angle) * h
			
			# add point to the array of points that will make our shape
			polyPts.push_back(Vector2(x, y))
		# end for
		
		# complete the polygon by adding the first to the last
		polyPts.push_back(polyPts[0])
	# end if
	
	# setup collision shapes
	collisionShape.set_polygon(polyPts)
	var areaCollisionShape = collisionShape.duplicate()
	placementHelpArea.add_child(areaCollisionShape)
# end _ready

func is_overlapping() -> bool:
	print("IS OVERLAPPING")
	print(placementHelpArea.has_overlapping_areas())
	print(placementHelpArea.has_overlapping_bodies())
	return (placementHelpArea.has_overlapping_areas() or placementHelpArea.has_overlapping_bodies())

func cloneSelf(dir: String):
	clones[dir] = self.duplicate()
	clones[dir].cloned = true
	clones[dir].polyPts = polyPts
	clones[dir].color = color
	
	if (dir == 'corner'):
		var x = 0
		var y = 0
		if (clones['right'] != null):
			x = clones['right'].global_position.x
		else:
			x = clones['left'].global_position.x
			
		if (clones['top'] != null):
			y = clones['top'].global_position.y
		else:
			y = clones['bottom'].global_position.y
			
		clones[dir].global_position = Vector2(x, y)
	else:
		match dir:
			'left':
				clones[dir].transform.origin = Vector2(global_position.x - screen_size.x, global_position.y)
			'right':
				clones[dir].transform.origin = Vector2(global_position.x + screen_size.x, global_position.y)
			'top':
				clones[dir].transform.origin = Vector2(global_position.x, global_position.y - screen_size.y)
			'bottom':
				clones[dir].transform.origin = Vector2(global_position.x, global_position.y + screen_size.y)
	# end if

	get_parent().call_deferred('add_child', clones[dir])
	clones[dir].connect('linear_velocity_changed', linearVelocityChanged)
	clones[dir].connect('angular_velocity_changed', angularVelocityChanged)
	clones[dir].connect('take_hit', reduce_strength)
# end cloneSelf

func linearVelocityChanged(vec):
	for dir in clones:
		if clones[dir] != null:
			clones[dir].linear_velocity = vec
	linear_velocity = vec
# linearVelocityChanged
	
func angularVelocityChanged(rad):
	for dir in clones:
		if clones[dir] != null:
			clones[dir].angular_velocity = rad
	angular_velocity = rad
# end angularVelocityChanged

func colorChanged(colr):
	if not cloned:
		for dir in clones:
			if clones[dir] != null:
				clones[dir].color = colr
		color = colr
# end colorChanged
	
func removeClone(dir: String):
	if clones[dir] != null:
		clones[dir].queue_free()
		clones[dir] = null
# end removeClone

func freeClones():
	for dir in clones:
		if clones[dir] != null:
			removeClone(dir)
# end freeClones

func _integrate_forces(state):
		
	if not cloned:
			
		# check to see if the node is starting to go offscreen and create a clone for the opposite
		# side of the screen such that appears to wrap around the screen
		if global_position.x + radius > screen_size.x and clones['left'] == null:
			cloneSelf('left')
		if global_position.x - radius < 0 and clones['right'] == null:
			cloneSelf('right')
		if global_position.y + radius > screen_size.y and clones['top'] == null:
			cloneSelf('top')
		if global_position.y - radius < 0 and clones['bottom'] == null:
			cloneSelf('bottom')
			
		# fix opposing corner problem
		if (clones['right'] != null or clones['left'] != null) and (clones['top'] != null or clones['bottom'] != null) and clones['corner'] == null:
			cloneSelf('corner')
		
		# swap the original object by wrapping it around the screen using state.transform.origin
		if global_position.x > screen_size.x:
			removeClone('left')
			state.transform.origin.x = 1
		if global_position.x < 0:
			removeClone('right')
			state.transform.origin.x = screen_size.x - 1
		if global_position.y > screen_size.y:
			removeClone('top')
			state.transform.origin.y = 0
		if global_position.y < 0:
			removeClone('bottom')
			state.transform.origin.y = screen_size.y
		
		# removes clones created when the actual node swaps sides then moves away from the edge but
		# leaves the clone that gets created when the swap occurs and the clone moves entirely offscreen
		if global_position.x + radius < screen_size.x and clones['left'] != null:
			removeClone('left')
		if global_position.x - radius > 0 and clones['right'] != null:
			removeClone('right')
		if global_position.y + radius < screen_size.y and clones['top'] != null:
			removeClone('top')
		if global_position.y - radius > 0 and clones['bottom'] != null:
			removeClone('bottom')
			
		if (clones['right'] == null and clones['left'] == null) or (clones['top'] == null and clones['bottom'] == null) and clones['corner'] != null:
			removeClone('corner')
	# end if
# end _integrate_forces
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
	if lv == Vector2.ZERO:
		lv = linear_velocity
	if av == 0.0:
		av = angular_velocity
		
	if lv != linear_velocity:
		if cloned:
			linear_velocity_changed.emit(linear_velocity)
		else: # copy lv to all clones
			linearVelocityChanged(linear_velocity)
	if av != angular_velocity:
		if cloned:
			angular_velocity_changed.emit(angular_velocity)
		else:
			angularVelocityChanged(angular_velocity)
		
	lv = linear_velocity
	av = angular_velocity
	
	var colliders = get_colliding_bodies()
	if colliders.size() > 0:
		for n in colliders:
			var crash = rock_crash.instantiate()
			#var vec_between: Vector2 = n.global_position - global_position
			var vec_btw_normalized: Vector2 = (n.global_position - global_position).normalized()
			var vec_to_collision: Vector2 = vec_btw_normalized * radius
			crash.global_position = global_position + vec_to_collision
			get_parent().add_child(crash)
			crash.get_child(0).color = color
			crash.get_child(0).emitting = true
			
	match size:
		'lg':
			if strength <= 6:
				color = Color.YELLOW
				colorChanged(color)
		'md':
			if strength <= 3:
				color = Color.YELLOW
				colorChanged(color)
			
	if strength == 1:
		color = Color.RED
		colorChanged(color)
# end _phsics_process

func reduce_strength():
	strength -= 1
	
	if strength <= 0:
		freeClones()
		destroyed.emit(position, size)
		queue_free()
		
func take_damange():
	take_hit.emit()
	reduce_strength()
