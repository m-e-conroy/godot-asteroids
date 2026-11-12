extends CharacterBody2D

signal bullet_impact(pos)
signal fired_projectile(pos, rot)
signal shield_strength_change(strength)
signal ship_destroyed(pos)
signal ship_respawned

var bullet = preload("res://characters/bullet.tscn")
var emp_scene = preload("res://effects/emp_shockwave.tscn")

@onready var SCREEN_SIZE := get_viewport_rect().size
@onready var PARENT := get_parent()

@export_group('Motion Parameters')
@export var ACCELERATION := 220.0
@export var MAX_SPEED := 320.0
@export var ROTATION_ACCELERATION := 24.0
@export var MAX_ROTATION_SPEED := 4.5
@export var ROTATION_STABILIZATION := 30.0 # Dampens rotation to 0 in ~0.15s
@export var SPACE_DECELERATION_TIME := 5.0 # Glides to stop over ~5.0 seconds

var TURN_LEFT := false
var TURN_RIGHT := false
var THRUST := false
var SHIELD := false
var FIRE := false
var FIRE_HELD := false
var STOPPED := true

# coordinates to draw shapes that represent the ship and various ship elements
@export_group('Ship Parameters') 
@export var PROJECTILE_LIMIT := 4
@export var SHIELD_STRENGTH := 100.0
@export var MASS := 0.2

enum ForceFieldState { READY, ACTIVE, RECHARGING }
var force_field_state: ForceFieldState = ForceFieldState.READY

enum WeaponMode { NORMAL, TRIPLE_SHOT, RAPID_FIRE }
var weapon_mode: WeaponMode = WeaponMode.NORMAL
var weapon_timer: float = 0.0
const WEAPON_BUFF_DURATION: float = 10.0
var rapid_fire_cooldown: float = 0.0
const RAPID_FIRE_INTERVAL: float = 0.12

const FORCE_FIELD_ACTIVE_TIME: float = 4.0
const FORCE_FIELD_RECHARGE_TIME: float = 12.0

var force_field_active_timer: float = 0.0
var force_field_recharge_timer: float = 0.0

var rotation_speed := 0.0
var projectile_cnt := 0
var previousShieldStrength := 100.0
var is_dead := false
var is_invulnerable := false

func _input(event):
	if is_dead:
		return
	if event.is_action_pressed("thrust"):
		THRUST = true
	elif event.is_action_pressed("turn_left"):
		TURN_LEFT = true
	elif event.is_action_pressed("turn_right"):
		TURN_RIGHT = true
	elif event.is_action_pressed("shield") and force_field_state == ForceFieldState.READY:
		activate_force_field()
		
	if event.is_action_pressed("fire"):
		FIRE_HELD = true
		FIRE = true
	elif event.is_action_released("fire"):
		FIRE_HELD = false
			
	if event.is_action_released("thrust"):
		THRUST = false
	elif event.is_action_released("turn_left"):
		TURN_LEFT = false
	elif event.is_action_released("turn_right"):
		TURN_RIGHT = false
		
# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("player")
	$ProjectileSpawnLocation.position = Vector2(0,-20.0) # set location where the ship's bullets will appear ahead of the ship
	
	# when a projectile is destroyed we can now fire an additional projectile
	if (PARENT != null) && (PARENT.has_signal("projectile_destroyed")):
		PARENT.connect("projectile_destroyed", _on_projectile_destroyed)
	
func _physics_process(delta):
	if is_dead:
		return

	# Manage Force Field Timers & State Transitions
	match force_field_state:
		ForceFieldState.ACTIVE:
			force_field_active_timer -= delta
			SHIELD_STRENGTH = (force_field_active_timer / FORCE_FIELD_ACTIVE_TIME) * 100.0
			if force_field_active_timer <= 0.0:
				deactivate_force_field()
		ForceFieldState.RECHARGING:
			force_field_recharge_timer += delta
			SHIELD_STRENGTH = 0.0
			if force_field_recharge_timer >= FORCE_FIELD_RECHARGE_TIME:
				force_field_state = ForceFieldState.READY
				force_field_recharge_timer = 0.0
				SHIELD_STRENGTH = 100.0
		ForceFieldState.READY:
			SHIELD_STRENGTH = 100.0

	# Manage Weapon Timers
	if weapon_mode != WeaponMode.NORMAL:
		weapon_timer -= delta
		if weapon_timer <= 0.0:
			weapon_mode = WeaponMode.NORMAL
			weapon_timer = 0.0

	# Forward Thrust & Maximum Speed Cap
	if THRUST:
		velocity -= transform.y * ACCELERATION * delta # -y because we drew our shape facing up that way
		if velocity.length() > MAX_SPEED:
			velocity = velocity.limit_length(MAX_SPEED)
		if !$Thrusters.playing:
			$Thrusters.play()
		STOPPED = false
	else:
		if $Thrusters.playing:
			$Thrusters.stop()
		if !STOPPED:
			# Passive space drag over ~5 seconds
			var drag: float = (MAX_SPEED / SPACE_DECELERATION_TIME) * delta
			velocity = velocity.move_toward(Vector2.ZERO, drag)
			if velocity.length() < 6.0:
				velocity = Vector2.ZERO
				STOPPED = true

	# Tightened Inertial Turning with Snappy ~0.15s Auto-Stabilization
	if TURN_LEFT:
		rotation_speed -= ROTATION_ACCELERATION * delta
		rotation_speed = max(rotation_speed, -MAX_ROTATION_SPEED)
		if !$SideThrusters.playing:
			$SideThrusters.play()
	elif TURN_RIGHT:
		rotation_speed += ROTATION_ACCELERATION * delta
		rotation_speed = min(rotation_speed, MAX_ROTATION_SPEED)
		if !$SideThrusters.playing:
			$SideThrusters.play()
	else:
		if $SideThrusters.playing:
			$SideThrusters.stop()
		rotation_speed = move_toward(rotation_speed, 0.0, ROTATION_STABILIZATION * delta)
		
	# Weapon firing handling
	if weapon_mode == WeaponMode.RAPID_FIRE:
		rapid_fire_cooldown -= delta
		if (FIRE or FIRE_HELD) and rapid_fire_cooldown <= 0.0:
			_fire_weapon()
			rapid_fire_cooldown = RAPID_FIRE_INTERVAL
		FIRE = false
	else:
		if FIRE:
			_fire_weapon()
			FIRE = false
		
	rotation += rotation_speed * delta
	
	# wrap screen around to the other side if the player or object should fall out of bounds of the window
	position.x = wrapf(position.x, 0, SCREEN_SIZE.x)
	position.y = wrapf(position.y, 0, SCREEN_SIZE.y)
	
	var collision = move_and_collide(velocity * delta)
	if collision:
		if force_field_state == ForceFieldState.ACTIVE:
			var normal: Vector2 = collision.get_normal()
			var current_speed: float = velocity.length()
			velocity = velocity.bounce(normal) * 1.15
			if velocity.length() < 160.0:
				velocity = normal * 160.0
			
			var collider = collision.get_collider()
			if collider is RigidBody2D:
				var push_impulse: Vector2 = -normal * max(current_speed * 1.8, 280.0)
				collider.apply_central_impulse(push_impulse)
			elif collider is CharacterBody2D:
				collider.velocity = -normal * max(current_speed * 1.5, 220.0)
		elif !is_invulnerable:
			destroy_ship()
			return
		
	# let game know the ship's shield strength has changed
	if previousShieldStrength != SHIELD_STRENGTH:
		previousShieldStrength = SHIELD_STRENGTH
		shield_strength_change.emit(SHIELD_STRENGTH)
		
# when a projectile is destroyed reduce the projectile's fired count so we may fire again
func _on_projectile_destroyed():
	projectile_cnt = max(0, projectile_cnt - 1)

func _fire_weapon():
	match weapon_mode:
		WeaponMode.NORMAL:
			if projectile_cnt < PROJECTILE_LIMIT:
				$Laser.play()
				fired_projectile.emit($ProjectileSpawnLocation.global_position, rotation)
				projectile_cnt += 1
		WeaponMode.TRIPLE_SHOT:
			if projectile_cnt < PROJECTILE_LIMIT * 3:
				$Laser.play()
				var forward: Vector2 = -transform.y
				var right: Vector2 = transform.x
				var spawn_center: Vector2 = $ProjectileSpawnLocation.global_position
				var spawn_left: Vector2 = spawn_center - right * 9.0 + forward * 3.0
				var spawn_right: Vector2 = spawn_center + right * 9.0 + forward * 3.0
				fired_projectile.emit(spawn_center, rotation)
				fired_projectile.emit(spawn_left, rotation - 0.22)
				fired_projectile.emit(spawn_right, rotation + 0.22)
				projectile_cnt += 3
		WeaponMode.RAPID_FIRE:
			if projectile_cnt < PROJECTILE_LIMIT * 4:
				$Laser.play()
				fired_projectile.emit($ProjectileSpawnLocation.global_position, rotation)
				projectile_cnt += 1

func apply_powerup(type_int: int):
	match type_int:
		0: # TRIPLE_SHOT
			weapon_mode = WeaponMode.TRIPLE_SHOT
			weapon_timer = WEAPON_BUFF_DURATION
		1: # RAPID_FIRE
			weapon_mode = WeaponMode.RAPID_FIRE
			weapon_timer = WEAPON_BUFF_DURATION
			rapid_fire_cooldown = 0.0
		2: # EMP_BLAST
			var emp = emp_scene.instantiate()
			emp.global_position = global_position
			get_parent().add_child(emp)
		3: # SHIELD_RECHARGE
			if force_field_state == ForceFieldState.ACTIVE:
				force_field_active_timer = FORCE_FIELD_ACTIVE_TIME
				SHIELD_STRENGTH = 100.0
			else:
				force_field_state = ForceFieldState.READY
				force_field_active_timer = 0.0
				force_field_recharge_timer = 0.0
				SHIELD_STRENGTH = 100.0
			previousShieldStrength = 100.0
			shield_strength_change.emit(100.0)

func activate_force_field():
	if force_field_state != ForceFieldState.READY:
		return
	force_field_state = ForceFieldState.ACTIVE
	force_field_active_timer = FORCE_FIELD_ACTIVE_TIME
	SHIELD = true
	$ForceFieldCollision.set_deferred("disabled", false)
	$CollisionPolygon2D.set_deferred("disabled", true)
	$Shields.play()

func deactivate_force_field():
	force_field_state = ForceFieldState.RECHARGING
	force_field_recharge_timer = 0.0
	SHIELD = false
	$ForceFieldCollision.set_deferred("disabled", true)
	$CollisionPolygon2D.set_deferred("disabled", false)
	if $Shields.playing:
		$Shields.stop()

func destroy_ship():
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	rotation_speed = 0.0
	THRUST = false
	TURN_LEFT = false
	TURN_RIGHT = false
	SHIELD = false
	weapon_mode = WeaponMode.NORMAL
	weapon_timer = 0.0
	FIRE_HELD = false
	projectile_cnt = 0
	force_field_state = ForceFieldState.READY
	force_field_active_timer = 0.0
	force_field_recharge_timer = 0.0
	if $Thrusters.playing:
		$Thrusters.stop()
	if $SideThrusters.playing:
		$SideThrusters.stop()
	if $Shields.playing:
		$Shields.stop()
	
	$CollisionPolygon2D.set_deferred("disabled", true)
	$ForceFieldCollision.set_deferred("disabled", true)
	$ShieldArea/CollisionShape2D.set_deferred("disabled", true)
	$Sprite2D.visible = false
	
	ship_destroyed.emit(global_position)

func respawn(spawn_pos: Vector2):
	global_position = spawn_pos
	velocity = Vector2.ZERO
	rotation_speed = 0.0
	rotation = 0.0
	is_dead = false
	weapon_mode = WeaponMode.NORMAL
	weapon_timer = 0.0
	FIRE_HELD = false
	projectile_cnt = 0
	force_field_state = ForceFieldState.READY
	force_field_active_timer = 0.0
	force_field_recharge_timer = 0.0
	SHIELD = false
	SHIELD_STRENGTH = 100.0
	previousShieldStrength = 100.0
	shield_strength_change.emit(SHIELD_STRENGTH)
	
	$Sprite2D.visible = true
	$CollisionPolygon2D.set_deferred("disabled", true)
	$ForceFieldCollision.set_deferred("disabled", true)
	$ShieldArea/CollisionShape2D.set_deferred("disabled", false)
	
	start_invulnerability(2.0)
	ship_respawned.emit()

func start_invulnerability(duration: float = 2.0):
	is_invulnerable = true
	$CollisionPolygon2D.set_deferred("disabled", true)
	var tween = create_tween()
	for i in range(6):
		tween.tween_property($Sprite2D, "modulate:a", 0.2, duration / 12.0)
		tween.tween_property($Sprite2D, "modulate:a", 1.0, duration / 12.0)
	tween.tween_callback(func():
		is_invulnerable = false
		if not is_dead and force_field_state != ForceFieldState.ACTIVE:
			$CollisionPolygon2D.set_deferred("disabled", false)
	)

func take_damage(amount: float = 10.0):
	if is_invulnerable or is_dead:
		return
	if force_field_state == ForceFieldState.ACTIVE:
		return
	destroy_ship()

# Backwards compatibility alias
func take_damange():
	take_damage()
