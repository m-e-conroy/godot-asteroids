extends Node2D

signal projectile_destroyed

@onready var screen_size = get_viewport_rect().size

var bullet = preload("res://characters/bullet.tscn")
var asteroidScn = preload("res://Enemies/Asteroid/asteroid.tscn")
var rock_crash = preload("res://effects/rock_crash.tscn")
var ship_explosion_scene = preload("res://effects/ship_explosion.tscn")
var saucer_scene = preload("res://Enemies/Saucer/saucer.tscn")
var hud_scene = preload("res://ui/hud.tscn")
var welcome_screen_scene = preload("res://ui/welcome_screen.tscn")
var score_manager_script = preload("res://scripts/score_manager.gd")

var rnd = RandomNumberGenerator.new()

enum GameState { WELCOME, PLAYING, GAME_OVER }
var game_state: GameState = GameState.WELCOME

var clones: Dictionary = {}
var current_wave: int = 1
var saucer_spawn_timer: float = 8.0
var score_manager: Node = null
var hud: CanvasLayer = null
var welcome_screen: CanvasLayer = null
var can_restart: bool = false
var game_over_return_timer: float = 0.0
const GAME_OVER_TIMEOUT: float = 10.0

# Called when the node enters the scene tree for the first time.
func _ready():
	rnd.randomize()
	game_state = GameState.WELCOME
	can_restart = false
	
	score_manager = score_manager_script.new()
	add_child(score_manager)
	
	hud = hud_scene.instantiate()
	add_child(hud)
	hud.connect_score_manager(score_manager)
	hud.set_player($player)
	hud.visible = false
	
	welcome_screen = welcome_screen_scene.instantiate()
	add_child(welcome_screen)
	welcome_screen.set_high_score(score_manager.high_score)
	welcome_screen.launch_requested.connect(_on_welcome_launch)
	
	$player.visible = false
	$player.is_dead = true
	$player.global_position = screen_size / 2.0
	$player.connect("bullet_impact", showBulletImpact)
	$player.connect("fired_projectile", _on_player_fired_projectile)
	$player.connect("ship_destroyed", _on_player_ship_destroyed)
	
	generate_ambient_asteroids(6)

func _on_welcome_launch():
	start_game()

func start_game():
	# Clear ambient asteroids
	for a in get_tree().get_nodes_in_group("asteroids"):
		a.queue_free()
		
	game_state = GameState.PLAYING
	if hud != null:
		hud.visible = true
		hud.hide_game_over()
		
	current_wave = 1
	saucer_spawn_timer = rnd.randf_range(14.0, 22.0)
	
	if score_manager != null:
		score_manager.reset_game()
		
	$player.visible = true
	$player.respawn(screen_size / 2.0)
	generateAsteroids()

func return_to_welcome():
	can_restart = false
	game_state = GameState.WELCOME
	
	# Clear existing enemies, projectiles, pickups, and asteroids
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	for b_node in get_tree().get_nodes_in_group("enemy_bullets"):
		b_node.queue_free()
	for pu in get_tree().get_nodes_in_group("powerups"):
		pu.queue_free()
	for a in get_tree().get_nodes_in_group("asteroids"):
		a.queue_free()
		
	if hud != null:
		hud.visible = false
		hud.hide_game_over()
		
	$player.visible = false
	$player.is_dead = true
	
	if welcome_screen != null:
		var hs = score_manager.high_score if score_manager != null else 0
		welcome_screen.reset_to_welcome(hs)
		
	generate_ambient_asteroids(6)

func _input(event):
	if game_state == GameState.GAME_OVER and can_restart:
		if event is InputEventKey and event.pressed and not event.is_echo():
			if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_R:
				restart_game()
			elif event.keycode == KEY_ESCAPE:
				return_to_welcome()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if game_state == GameState.GAME_OVER:
		game_over_return_timer -= delta
		if hud != null:
			hud.set_game_over_countdown(game_over_return_timer)
		if game_over_return_timer <= 0.0:
			return_to_welcome()
		return
		
	if game_state != GameState.PLAYING:
		return
		
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
			
func generate_ambient_asteroids(count: int = 6):
	var sizes = ['lg', 'md', 'sm']
	for i in count:
		var a = asteroidScn.instantiate()
		a.SIZE = sizes[rnd.randi_range(0, 2)]
		a.position = Vector2(rnd.randf_range(40, screen_size.x - 40), rnd.randf_range(40, screen_size.y - 40))
		a.linear_velocity = Vector2(rnd.randf_range(8, 20) * randomPosNegOne(), rnd.randf_range(8, 20) * randomPosNegOne())
		a.angular_velocity = (randomPosNegOne() * rnd.randf_range(5, 25)) * PI / 180.0
		add_child(a)
		a.connect("destroyed", asteroidDestroyed)

func asteroidDestroyed(pos, size):
	# award score based on asteroid size only during active play
	if game_state == GameState.PLAYING and score_manager != null:
		match size:
			'lg': score_manager.add_score(20)
			'md': score_manager.add_score(50)
			'sm': score_manager.add_score(100)
			'xs': score_manager.add_score(150)

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
	if game_state != GameState.PLAYING:
		return
	var remaining = 0
	for a in get_tree().get_nodes_in_group("asteroids"):
		if is_instance_valid(a) and !a.is_queued_for_deletion() and ("CLONED" in a and !a.CLONED):
			remaining += 1
	if remaining == 0:
		current_wave += 1
		if score_manager != null:
			score_manager.set_wave(current_wave)
		get_tree().create_timer(2.0).timeout.connect(func():
			if game_state == GameState.PLAYING:
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
	
	var has_lives: bool = true
	if score_manager != null:
		has_lives = score_manager.lose_life()
	if has_lives:
		get_tree().create_timer(2.0).timeout.connect(_respawn_player)
	else:
		game_state = GameState.GAME_OVER
		game_over_return_timer = GAME_OVER_TIMEOUT
		if hud != null:
			hud.set_game_over_countdown(game_over_return_timer)
		can_restart = false
		get_tree().create_timer(1.0).timeout.connect(func(): can_restart = true)

func restart_game():
	can_restart = false
	game_state = GameState.PLAYING
	# Clear existing enemies, projectiles, pickups, and asteroids
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	for b_node in get_tree().get_nodes_in_group("enemy_bullets"):
		b_node.queue_free()
	for pu in get_tree().get_nodes_in_group("powerups"):
		pu.queue_free()
	for a in get_tree().get_nodes_in_group("asteroids"):
		a.queue_free()
		
	current_wave = 1
	saucer_spawn_timer = 8.0
	if score_manager != null:
		score_manager.reset_game()
	if hud != null:
		hud.visible = true
		hud.hide_game_over()
		
	$player.visible = true
	$player.respawn(screen_size / 2.0)
	generateAsteroids()

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

