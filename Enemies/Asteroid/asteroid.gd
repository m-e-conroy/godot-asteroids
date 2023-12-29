extends RigidBody2D

signal destroyed(pos, sz)
signal linear_velocity_changed(vec)
signal angular_velocity_changed(rad)
signal take_hit

var ROCK_CRASH_SCENE = preload("res://effects/rock_crash.tscn")

@onready var SPRITE := $Sprite2D
@onready var COLLISION_SHAPE := $CollisionPolygon2D
@onready var PLACEMENT_HELP_AREA := $Area2D
@onready var SCREEN_SIZE := get_viewport_rect().size

var SIZE: String = 'lg'
var STRENGTH: int = 1
var COLOR: Color = Color.LAWN_GREEN

#var polyPts: Array = []
var radius := 100.0
var minRadius := 75.0
var lv: Vector2 = Vector2.ZERO
var av: float = 0.0

# clones will keep track of asteroid copies for screen flip purposes when an asteroid should overlap more than one edge of the screen
var clones: Dictionary = {
	"top": null,
	"bottom": null,
	"left": null,
	"right": null,
	"corner": null
}
var CLONED: bool = false

var rnd = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	rnd.randomize()
	
	linear_damp = 0 # how much linear movement slows down by in open space (friction)
	angular_damp = 0 # how much rotational movement slows down by in open space (friction)
	gravity_scale = 0
	contact_monitor = true # turn on collision detection
	max_contacts_reported = 10
	
	match SIZE:
		'lg':
			mass = rnd.randf_range(150, 200)
			STRENGTH = rnd.randi_range(15,20)
		'md':
			mass = rnd.randf_range(80, 130)
			STRENGTH = rnd.randi_range(10,15)
		'sm':
			mass = rnd.randf_range(10, 60)
			STRENGTH = rnd.randi_range(5,10)
		'xs':
			mass = rnd.randf_range(3, 10)
			STRENGTH = rnd.randi_range(1,5)
# end _ready

func is_overlapping() -> bool:
	return (PLACEMENT_HELP_AREA.has_overlapping_areas() or PLACEMENT_HELP_AREA.has_overlapping_bodies())

func cloneSelf(dir: String):
	clones[dir] = self.duplicate()
	clones[dir].CLONED = true
	clones[dir].get_node("Sprite2D").set("polyPts", SPRITE.polyPts)
	clones[dir].COLOR = COLOR
	
	# set the position of the clone
	if (dir == 'corner'):
		var x = 0
		var y = 0
		if (clones['right'] != null):
			clones[dir].global_position.x = clones['right'].global_position.x
		else:
			clones[dir].global_position.x = clones['left'].global_position.x
			
		if (clones['top'] != null):
			clones[dir].global_position.y = clones['top'].global_position.y
		else:
			clones[dir].global_position.y = clones['bottom'].global_position.y
	else:
		match dir:
			'left':
				clones[dir].transform.origin = Vector2(global_position.x - SCREEN_SIZE.x, global_position.y)
			'right':
				clones[dir].transform.origin = Vector2(global_position.x + SCREEN_SIZE.x, global_position.y)
			'top':
				clones[dir].transform.origin = Vector2(global_position.x, global_position.y - SCREEN_SIZE.y)
			'bottom':
				clones[dir].transform.origin = Vector2(global_position.x, global_position.y + SCREEN_SIZE.y)
	# end if
	
	get_parent().call_deferred('add_child', clones[dir])
	clones[dir].connect('linear_velocity_changed', linearVelocityChanged)
	clones[dir].connect('angular_velocity_changed', angularVelocityChanged)
	clones[dir].connect('take_hit', reduceStrength)
# end cloneSelf

# called when there is a change in linear velocity and the clones need to be updated to reflect that
func linearVelocityChanged(vec):
	for dir in clones:
		if clones[dir] != null:
			clones[dir].linear_velocity = vec
	linear_velocity = vec
# linearVelocityChanged

# called when there is a change in angular velocity and the clones need to be updated to reflect that
func angularVelocityChanged(rad):
	for dir in clones:
		if clones[dir] != null:
			clones[dir].angular_velocity = rad
	angular_velocity = rad
# end angularVelocityChanged

# update the color of the clones
func colorChanged(colr):
	if !CLONED:
		for dir in clones:
			if clones[dir] != null:
				clones[dir].COLOR = colr
		COLOR = colr
# colorChanged
	
# remove a clone from view and free up the resource
func removeClone(dir: String):
	if clones[dir] != null:
		clones[dir].queue_free()
		clones[dir] = null
# removeClone

# removes all clones
func freeClones():
	for dir in clones:
		if clones[dir] != null:
			removeClone(dir)
# freeClones

func _integrate_forces(state):
	if not CLONED:
		# check to see if the node is starting to go offscreen and create a clone for the opposite
		# side of the screen such that appears to wrap around the screen
		if global_position.x + radius > SCREEN_SIZE.x and clones['left'] == null:
			cloneSelf('left')
		if global_position.x - radius < 0 and clones['right'] == null:
			cloneSelf('right')
		if global_position.y + radius > SCREEN_SIZE.y and clones['top'] == null:
			cloneSelf('top')
		if global_position.y - radius < 0 and clones['bottom'] == null:
			cloneSelf('bottom')
			
		# fix opposing corner problem
		if (clones['right'] != null or clones['left'] != null) and (clones['top'] != null or clones['bottom'] != null) and clones['corner'] == null:
			cloneSelf('corner')
		
		# swap the original object by wrapping it around the screen using state.transform.origin
		if global_position.x > SCREEN_SIZE.x:
			removeClone('left')
			state.transform.origin.x = 0
		if global_position.x < 0:
			removeClone('right')
			state.transform.origin.x = SCREEN_SIZE.x - 1
		if global_position.y > SCREEN_SIZE.y:
			removeClone('top')
			state.transform.origin.y = 0
		if global_position.y < 0:
			removeClone('bottom')
			state.transform.origin.y = SCREEN_SIZE.y
		
		# removes clones created when the actual node swaps sides then moves away from the edge but
		# leaves the clone that gets created when the swap occurs and the clone moves entirely offscreen
		if global_position.x + radius < SCREEN_SIZE.x and clones['left'] != null:
			removeClone('left')
		if global_position.x - radius > 0 and clones['right'] != null:
			removeClone('right')
		if global_position.y + radius < SCREEN_SIZE.y and clones['top'] != null:
			removeClone('top')
		if global_position.y - radius > 0 and clones['bottom'] != null:
			removeClone('bottom')
			
		if (clones['right'] == null and clones['left'] == null) or (clones['top'] == null and clones['bottom'] == null) and clones['corner'] != null:
			removeClone('corner')
	# if
# _integrate_forces
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
	if lv == Vector2.ZERO:
		lv = linear_velocity
	if av == 0.0:
		av = angular_velocity
		
	if lv != linear_velocity:
		if CLONED:
			linear_velocity_changed.emit(linear_velocity)
		else: # copy lv to all clones
			linearVelocityChanged(linear_velocity)
	if av != angular_velocity:
		if CLONED:
			angular_velocity_changed.emit(angular_velocity)
		else:
			angularVelocityChanged(angular_velocity)
		
	lv = linear_velocity
	av = angular_velocity
	
	var colliders = get_colliding_bodies()
	if colliders.size() > 0:
		for n in colliders:
			var crash = ROCK_CRASH_SCENE.instantiate()
			#var vec_between: Vector2 = n.global_position - global_position
			var vec_btw_normalized: Vector2 = (n.global_position - global_position).normalized()
			var vec_to_collision: Vector2 = vec_btw_normalized * radius
			crash.global_position = global_position + vec_to_collision
			get_parent().add_child(crash)
			crash.get_child(0).color = COLOR
			crash.get_child(0).emitting = true
		# for
	# if
			
	match SIZE:
		'lg':
			if STRENGTH <= 10:
				COLOR = Color.YELLOW
				colorChanged(COLOR)
		'md':
			if STRENGTH <= 5:
				COLOR = Color.YELLOW
				colorChanged(COLOR)
		'sm':
			if STRENGTH <= 3:
				COLOR = Color.YELLOW
				colorChanged(COLOR)
		'xs':
			if STRENGTH <= 2:
				COLOR = Color.YELLOW
				colorChanged(COLOR)
	# match
			
	if STRENGTH == 1:
		COLOR = Color.RED
		colorChanged(COLOR)
# _physics_process

func reduceStrength():
	STRENGTH -= 1
	# if strength is 0 then destroy the asteroid and any associated clones
	if STRENGTH <= 0:
		freeClones()
		destroyed.emit(position, SIZE)
		queue_free()
# reduceStrength
		
func takeDamange():
	take_hit.emit()
	reduceStrength()
# takeDamage
