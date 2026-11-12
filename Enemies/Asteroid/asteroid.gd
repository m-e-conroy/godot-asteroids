extends RigidBody2D

signal destroyed(pos, sz)
signal linear_velocity_changed(vec)
signal angular_velocity_changed(rad)
signal take_hit(amount: int)

var ROCK_CRASH_SCENE = preload("res://effects/rock_crash.tscn")

@onready var SPRITE := $Sprite2D
@onready var COLLISION_SHAPE := $CollisionPolygon2D
@onready var PLACEMENT_HELP_AREA := $Area2D
@onready var SCREEN_SIZE := get_viewport_rect().size

var SIZE: String = 'lg'
var size: String:
	get:
		return SIZE
	set(val):
		SIZE = val
var STRENGTH: int = 1
var MAX_STRENGTH: int = 1
var COLOR: Color = Color.LAWN_GREEN

#var polyPts: Array = []
var radius := 100.0
var minRadius := 75.0
var lv: Vector2 = Vector2.ZERO
var av: float = 0.0
var crash_cooldown := 0.0

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
	add_to_group("asteroids")
	
	linear_damp = 0 # how much linear movement slows down by in open space (friction)
	angular_damp = 0 # how much rotational movement slows down by in open space (friction)
	gravity_scale = 0
	contact_monitor = true # turn on collision detection
	max_contacts_reported = 10
	
	if !CLONED:
		match SIZE:
			'lg':
				mass = rnd.randf_range(150, 200)
				STRENGTH = rnd.randi_range(15, 20)
				minRadius = 80.0
				radius = 100.0
			'md':
				mass = rnd.randf_range(80, 130)
				STRENGTH = rnd.randi_range(10, 15)
				minRadius = 55.0
				radius = 75.0
			'sm':
				mass = rnd.randf_range(10, 60)
				STRENGTH = rnd.randi_range(5, 10)
				minRadius = 20.0
				radius = 30.0
			'xs':
				mass = rnd.randf_range(3, 10)
				STRENGTH = rnd.randi_range(1, 5)
				minRadius = 6.0
				radius = 12.0

		MAX_STRENGTH = STRENGTH
		update_color()
# end _ready

func is_overlapping() -> bool:
	return (PLACEMENT_HELP_AREA.has_overlapping_areas() or PLACEMENT_HELP_AREA.has_overlapping_bodies())

func cloneSelf(dir: String):
	clones[dir] = self.duplicate()
	clones[dir].CLONED = true
	clones[dir].get_node("Sprite2D").set("polyPts", SPRITE.polyPts)
	clones[dir].COLOR = COLOR
	clones[dir].radius = radius
	clones[dir].minRadius = minRadius
	clones[dir].SIZE = SIZE
	clones[dir].MAX_STRENGTH = MAX_STRENGTH
	clones[dir].STRENGTH = STRENGTH
	
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

func _integrate_forces(state: PhysicsDirectBodyState2D):
	# Enforce maximum velocity bounds per asteroid size to prevent physics runaway
	var max_spd: float = 45.0
	match SIZE:
		'lg': max_spd = 45.0
		'md': max_spd = 70.0
		'sm': max_spd = 100.0
		'xs': max_spd = 140.0
	
	if state.linear_velocity.length() > max_spd:
		state.linear_velocity = state.linear_velocity.limit_length(max_spd)
		
	# Enforce reasonable angular velocity bounds
	state.angular_velocity = clamp(state.angular_velocity, -2.5, 2.5)

	# Handle collision VFX at exact physical contact point
	var contact_count: int = state.get_contact_count()
	if contact_count > 0 and crash_cooldown <= 0.0:
		for i in range(contact_count):
			var collider = state.get_contact_collider_object(i)
			if collider == null:
				continue
			
			# If colliding with a saucer, destroy the saucer immediately
			if collider.is_in_group("saucers") or collider.name.begins_with("saucer"):
				if collider.has_method("destroy"):
					collider.destroy()

			# If colliding with another asteroid, only let the one with lower instance ID spawn to prevent duplicate VFX
			if collider is RigidBody2D and collider.get_instance_id() > get_instance_id():
				continue
				
			var local_contact: Vector2 = state.get_contact_local_position(i)
			var collider_contact: Vector2 = state.get_contact_collider_position(i)
			var contact_pos: Vector2 = (local_contact + collider_contact) * 0.5
			
			if contact_pos == Vector2.ZERO:
				var collider_radius: float = collider.get("radius") if collider.get("radius") != null else 50.0
				var to_collider: Vector2 = collider.global_position - global_position
				var dist: float = to_collider.length()
				var dir: Vector2 = to_collider.normalized() if dist > 0.001 else Vector2.RIGHT
				var total_r: float = radius + collider_radius
				contact_pos = global_position + dir * (radius * dist / total_r if total_r > 0 else radius)
				
			var contact_normal: Vector2 = state.get_contact_local_normal(i)
			if contact_normal == Vector2.ZERO:
				var to_col: Vector2 = collider.global_position - global_position
				contact_normal = to_col.normalized() if to_col.length_squared() > 0.0001 else Vector2.RIGHT
			spawn_crash_effect(contact_pos, contact_normal)
			crash_cooldown = 0.15 # 150ms debounce
			break

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
func _physics_process(delta):
	if crash_cooldown > 0.0:
		crash_cooldown -= delta

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
# _physics_process

func spawn_crash_effect(pos: Vector2, contact_normal: Vector2 = Vector2.RIGHT):
	var impact_fx = load("res://effects/impact_fx.gd")
	if impact_fx != null:
		impact_fx.spawn_asteroid_crash(get_parent(), pos, contact_normal, COLOR)

func update_color():
	var new_color: Color = Color.LAWN_GREEN
	
	# If asteroid started low (strength 1 or 2)
	if MAX_STRENGTH <= 1:
		new_color = Color.RED
	elif MAX_STRENGTH == 2:
		if STRENGTH <= 1:
			new_color = Color.RED
		else:
			new_color = Color.YELLOW
	else:
		# Health ratio determines color progression: Green -> Yellow -> Red
		var ratio: float = float(STRENGTH) / float(MAX_STRENGTH)
		if ratio <= 0.30 or STRENGTH <= 2:
			new_color = Color.RED
		elif ratio <= 0.65:
			new_color = Color.YELLOW
		else:
			new_color = Color.LAWN_GREEN
			
	if COLOR != new_color:
		COLOR = new_color
		colorChanged(COLOR)

func reduceStrength(amount: int = 1):
	STRENGTH -= amount
	update_color()
	# if strength is 0 then destroy the asteroid and any associated clones
	if STRENGTH <= 0:
		freeClones()
		destroyed.emit(position, SIZE)
		queue_free()
# reduceStrength
		
func take_damage(amount: int = 1):
	take_hit.emit(amount)
	if not CLONED:
		reduceStrength(amount)

# Backwards compatibility aliases
func takeDamange():
	take_damage()

func take_damange():
	take_damage()
# takeDamage
