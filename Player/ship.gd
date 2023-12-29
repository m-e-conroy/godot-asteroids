extends CharacterBody2D

signal bullet_impact(pos)
signal fired_projectile(pos, rot)
signal shield_strength_change(strength)

var bullet = preload("res://characters/bullet.tscn")

@onready var SCREEN_SIZE := get_viewport_rect().size
@onready var PARENT := get_parent()

@export_group('Motion Parameters')
@export var ACCELERATION := 75.0
@export var ROTATION_ACCELERATION := .075
@export var SPACE_ROTATION_FRICTION := .05
@export var SPACE_FRICTION := .999

var TURN_LEFT := false
var TURN_RIGHT := false
var THRUST := false
var SHIELD := false
var FIRE := false
var STOPPED := true

# coordinates to draw shapes that represent the ship and various ship elements
@export_group('Ship Parameters') 
@export var PROJECTILE_LIMIT := 4
@export var SHIELD_STRENGTH := 100.0
@export var MASS := 0.2

var rotation_speed := 0.0
var projectile_cnt := 0
var previousShieldStrength := 100.0

func _input(event):
	if event.is_action_pressed("thrust"):
		THRUST = true
	elif event.is_action_pressed("turn_left"):
		TURN_LEFT = true
	elif event.is_action_pressed("turn_right"):
		TURN_RIGHT = true
	elif event.is_action_pressed("shield") && (SHIELD_STRENGTH > 0):
		$Shields.play()
		SHIELD = true
		
	if event.is_action_released("fire"):
		FIRE = true
			
	if event.is_action_released("thrust"):
		THRUST = false
	elif event.is_action_released("turn_left"):
		TURN_LEFT = false
	elif event.is_action_released("turn_right"):
		TURN_RIGHT = false
	elif event.is_action_released("shield"):
		SHIELD = false
		
# Called when the node enters the scene tree for the first time.
func _ready():
	$ProjectileSpawnLocation.position = Vector2(0,-20.0) # set location where the ship's bullets will appear ahead of the ship
	
	# when a projectile is destroyed we can now fire an additional projectile
	if (PARENT != null) && (PARENT.has_signal("projectile_destroyed")):
		PARENT.connect("projectile_destroyed", _on_projectile_destroyed)
	
func _physics_process(delta):
	if THRUST:
		velocity -= transform.y * ACCELERATION * delta # -y because we drew our shape facing up that way
		if !$Thrusters.playing:
			$Thrusters.play()
		STOPPED = false
	if TURN_LEFT:
		rotation_speed += -ROTATION_ACCELERATION
		if !$SideThrusters.playing:
			$SideThrusters.play()
	if TURN_RIGHT:
		rotation_speed += ROTATION_ACCELERATION
		if !$SideThrusters.playing:
			$SideThrusters.play()
		
	if FIRE:
		#fire($BulletSpawnLocation.global_position, rotation)
		if projectile_cnt < PROJECTILE_LIMIT:
			$Laser.play()
			fired_projectile.emit($ProjectileSpawnLocation.global_position, rotation)
			projectile_cnt += 1
		FIRE = false
		
	# if we aren't currently turning or hitting the gas then we need to slowly reduce the ship's motion
	if !TURN_LEFT and !TURN_RIGHT: # if we aren't actively turning slowly decrease rotation speed
		if $SideThrusters.playing:
			$SideThrusters.stop()
		if rotation_speed > 0.0:
			rotation_speed -= SPACE_ROTATION_FRICTION
		elif rotation_speed < 0.0:
			rotation_speed += SPACE_ROTATION_FRICTION
	if !THRUST: # if we aren't thrusting but we're still moving, slowly decrease velocity
		if $Thrusters.playing:
			$Thrusters.stop()
		if velocity.length() < 8 and !STOPPED:
			velocity = Vector2.ZERO
			STOPPED = true
		elif !STOPPED:
			velocity *= SPACE_FRICTION
		
	rotation += rotation_speed * delta
	
	# wrap screen around to the other side if the player or object should fall out of bounds of the window
	position.x = wrapf(position.x, 0, SCREEN_SIZE.x)
	position.y = wrapf(position.y, 0, SCREEN_SIZE.y)
	
	var collision = move_and_collide(velocity * delta)
	if collision && (!SHIELD || (SHIELD && (SHIELD_STRENGTH <= 0))):
		print('SHIP COLLISION')
		print(collision.get_collider())	
		
	# let game know the ship's shield strength has changed
	if previousShieldStrength != SHIELD_STRENGTH:
		previousShieldStrength = SHIELD_STRENGTH
		shield_strength_change.emit(SHIELD_STRENGTH)
		
# when a projectile is destroyed reduce the projectile's fired count so we may fire again
func _on_projectile_destroyed():
	projectile_cnt -= 1
	
#func bulletImpact(pos):
	#bullet_cnt -= 1
#	bullet_impact.emit(pos)
	
#func fire(pos, rot):
#	if bullet_cnt < bullet_limit:
#		var b = bullet.instantiate()
#		b.position = pos
#		b.rotation = rot
#		b.velocity -= b.transform.y * 275
#		$Laser.play()
#		get_parent().add_child(b)
#		b.connect('hit', bulletImpact)
#		bullet_cnt += 1
	
func take_damange():
	print('TEST HIT')
