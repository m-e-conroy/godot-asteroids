extends Node2D

signal projectile_destroyed

@onready var screen_size = get_viewport_rect().size

var bullet = preload("res://characters/bullet.tscn")
var asteroidScn = preload("res://Enemies/Asteroid/asteroid.tscn")
var rock_crash = preload("res://effects/rock_crash.tscn")
var ship_explosion_scene = preload("res://effects/ship_explosion.tscn")
var saucer_scene = preload("res://Enemies/Saucer/saucer.tscn")

var rnd = RandomNumberGenerator.new()

var clones: Dictionary = {}
var current_wave: int = 1
var saucer_spawn_timer: float = 8.0

# Called when the node enters the scene tree for the first time.
func _ready():
	rnd.randomize()
	$player.global_position = screen_size / 2
	$player.connect("bullet_impact", showBulletImpact)
	$player.connect("fired_projectile", _on_player_fired_projectile)
	$player.connect("ship_destroyed", _on_player_ship_destroyed)
	generateAsteroids()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	saucer_spawn_timer -= delta
	if saucer_spawn_timer <= 0.0:
		var active_saucers: int = 0
		for s in get_tree().get_nodes_in_group("saucers"):
			if is_instance_valid(s) and !s.is_queued_for_deletion():
				active_saucers += 1
				
		var max_saucers: int = 1 if current_wave <= 2 else 2
		if active_saucers < max_saucers:
			spawn_saucer()
		saucer_spawn_timer = rnd.randf_range(18.0, 26.0)

func spawn_saucer():
	var s = saucer_scene.instantiate()
	s.level = current_wave
	var from_left: bool = rnd.randf() > 0.5
	var start_x: float = -20.0 if from_left else screen_size.x + 20.0
	var start_y: float = rnd.randf_range(80.0, screen_size.y - 80.0)
	s.position = Vector2(start_x, start_y)
	s.direction = 1.0 if from_left else -1.0
	add_child(s)
	
func randomPosNegOne():
	var one = rnd.randf_range(-1,1)
	if one < 0:
		return -1
	else:
		return 1
# end randomPosNegOne

func generateAsteroids():
	var sizes = ['lg','md','sm','xs']
	var n = min(10, rnd.randi_range(4, 6) + current_wave - 1)
	
	for i in n:
		var a = asteroidScn.instantiate()
		a.SIZE = sizes[rnd.randi_range(0,3)]
		a.position = Vector2(rnd.randi_range(0, screen_size.x), rnd.randi_range(0, screen_size.y))
		a.linear_velocity = Vector2(rnd.randi_range(4,16) * randomPosNegOne(), rnd.randi_range(4,16) * randomPosNegOne())
		a.angular_velocity = (randomPosNegOne() * rnd.randi_range(1,45)) * PI / 180
		add_child(a)
		a.connect("destroyed", asteroidDestroyed)
			
func asteroidDestroyed(pos, size):
	# explosion
	match size:
		'lg': # break into 4 small, 2 small 1 medium, or 2 medium asteroids
			match rnd.randi_range(0,2):
				0:
					for i in 4:
						var a = asteroidScn.instantiate()
						a.SIZE = 'sm'
						a.position = pos
						a.linear_velocity = Vector2(rnd.randi_range(4,16) * randomPosNegOne(), rnd.randi_range(4,16) * randomPosNegOne())
						a.angular_velocity = (randomPosNegOne() * rnd.randi_range(1,45)) * PI / 180
						add_child(a)
						a.connect("destroyed", asteroidDestroyed)
				1:
					for i in 2:
						var a = asteroidScn.instantiate()
						a.SIZE = 'sm'
						a.position = pos
						a.linear_velocity = Vector2(rnd.randi_range(4,16) * randomPosNegOne(), rnd.randi_range(4,16) * randomPosNegOne())
						a.angular_velocity = (randomPosNegOne() * rnd.randi_range(1,45)) * PI / 180
						add_child(a)
						a.connect("destroyed", asteroidDestroyed)
				2:
					for i in 2:
						var a = asteroidScn.instantiate()
						a.SIZE = 'md'
						a.position = pos
						a.linear_velocity = Vector2(rnd.randi_range(4,16) * randomPosNegOne(), rnd.randi_range(4,16) * randomPosNegOne())
						a.angular_velocity = (randomPosNegOne() * rnd.randi_range(1,45)) * PI / 180
						add_child(a)
						a.connect("destroyed", asteroidDestroyed)
		'md': # break into 2 or 3 small ones
			var num := rnd.randi_range(2,3)
			for i in num:
				var a = asteroidScn.instantiate()
				
				a.SIZE = 'sm'
				a.position = pos
				a.linear_velocity = Vector2(rnd.randi_range(4,16) * randomPosNegOne(), rnd.randi_range(4,16) * randomPosNegOne())
				a.angular_velocity = (randomPosNegOne() * rnd.randi_range(1,45)) * PI / 180
				add_child(a)
				a.connect("destroyed", asteroidDestroyed)
	showAsteroidExplosion(pos)
	call_deferred("_check_wave_cleared")

func _check_wave_cleared():
	var remaining = 0
	for a in get_tree().get_nodes_in_group("asteroids"):
		if is_instance_valid(a) and !a.is_queued_for_deletion() and ("CLONED" in a and !a.CLONED):
			remaining += 1
	if remaining == 0:
		current_wave += 1
		get_tree().create_timer(2.0).timeout.connect(func():
			generateAsteroids()
			saucer_spawn_timer = rnd.randf_range(5.0, 9.0)
		)	

func _on_player_fired_projectile(pos: Vector2, rot: float):
	var b = bullet.instantiate()
	b.global_position = pos
	b.rotation = rot
	b.velocity = Vector2(0, -450.0).rotated(rot)
	b.add_collision_exception_with($player)
	add_child(b)
	b.connect("hit", showBulletImpact)
	b.connect("destroyed", _on_bullet_destroyed)

func _on_bullet_destroyed():
	projectile_destroyed.emit()	

func _on_player_ship_destroyed(pos: Vector2):
	var explosion = ship_explosion_scene.instantiate()
	explosion.global_position = pos
	add_child(explosion)
	get_tree().create_timer(2.0).timeout.connect(_respawn_player)

func _respawn_player():
	var center: Vector2 = screen_size / 2.0
	var safe_radius: float = 160.0
	for a in get_tree().get_nodes_in_group("asteroids"):
		if is_instance_valid(a) and !a.is_queued_for_deletion():
			var dist: float = a.global_position.distance_to(center)
			if dist < safe_radius:
				var away_dir: Vector2 = (a.global_position - center).normalized()
				if away_dir == Vector2.ZERO:
					away_dir = Vector2.RIGHT.rotated(rnd.randf() * 2.0 * PI)
				var a_radius: float = a.radius if "radius" in a else 60.0
				a.global_position = center + away_dir * (safe_radius + a_radius + 20.0)
				if a.linear_velocity.dot(away_dir) < 0.0:
					a.linear_velocity = a.linear_velocity.bounce(away_dir)
	$player.respawn(center)	

func showBulletImpact(pos):
	var crash = rock_crash.instantiate()
	crash.global_position = pos
	crash.get_child(0).amount = 25
	crash.get_child(0).color = Color.WHITE
	add_child(crash)
	crash.get_child(0).emitting = true
# end showBulletImpact

func showAsteroidExplosion(pos):
	var crash = rock_crash.instantiate()
	crash.global_position = pos
	crash.get_child(0).amount = 50
	crash.get_child(0).lifetime = 2
	crash.get_child(0).speed_scale = 2
	crash.get_child(0).color = Color.WHITE
	add_child(crash)
	crash.get_child(0).emitting = true
	
# end showAsteroidExplosion

