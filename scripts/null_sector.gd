extends Node2D

signal projectile_destroyed

@onready var screen_size = get_viewport_rect().size

var bullet = preload("res://characters/bullet.tscn")
var asteroidScn = preload("res://Enemies/Asteroid/asteroid.tscn")
var rock_crash = preload("res://effects/rock_crash.tscn")
var ship_explosion_scene = preload("res://effects/ship_explosion.tscn")
var saucer_scene = preload("res://Enemies/Saucer/saucer.tscn")
var boss_scene = preload("res://Enemies/Boss/procedural_boss.tscn")
var comet_scene = preload("res://Enemies/Hazards/comet.tscn")
var pulsar_scene = preload("res://Enemies/Hazards/pulsar.tscn")
var black_hole_scene = preload("res://Enemies/Hazards/black_hole.tscn")
var drone_scene = preload("res://Enemies/Drone/drone.tscn")
var hud_scene = preload("res://ui/hud.tscn")
var welcome_screen_scene = preload("res://ui/welcome_screen.tscn")
var pause_menu_scene = preload("res://ui/pause_menu.tscn")
var score_manager_script = preload("res://scripts/score_manager.gd")
var audio_manager_script = preload("res://scripts/audio_manager.gd")
var nebula_bg_script = preload("res://effects/nebula_background.gd")
var camera_shake_script = preload("res://scripts/camera_shake.gd")
var vector_shrapnel_script = preload("res://effects/vector_shrapnel.gd")
var crt_shader = preload("res://effects/crt_overlay.gdshader")

var rnd = RandomNumberGenerator.new()

enum GameState { WELCOME, PLAYING, GAME_OVER }
var game_state: GameState = GameState.WELCOME

enum WaveMutator { NONE, GRAVITY_WELL, PULSAR_CORE, COMET_TRANSIT, DRONE_SWARM, HYPER_DRIFT }
var active_mutator: WaveMutator = WaveMutator.NONE
var last_mutator: WaveMutator = WaveMutator.NONE
var comet_spawn_timer: float = 0.0

var clones: Dictionary = {}
var current_wave: int = 1
var saucer_spawn_timer: float = 8.0
var score_manager: Node = null
var audio_manager: Node = null
var hud: CanvasLayer = null
var welcome_screen: CanvasLayer = null
var pause_menu: CanvasLayer = null
var crt_layer: CanvasLayer = null
var can_restart: bool = false
var game_over_return_timer: float = 0.0
const GAME_OVER_TIMEOUT: float = 10.0

func _ready():
	rnd.randomize()
	game_state = GameState.WELCOME
	can_restart = false
	
	score_manager = score_manager_script.new()
	add_child(score_manager)
	
	audio_manager = audio_manager_script.new()
	add_child(audio_manager)
	
	hud = hud_scene.instantiate()
	add_child(hud)
	hud.connect_score_manager(score_manager)
	hud.set_player($player)
	hud.visible = false
	
	welcome_screen = welcome_screen_scene.instantiate()
	add_child(welcome_screen)
	welcome_screen.set_high_score(score_manager.high_score)
	welcome_screen.launch_requested.connect(_on_welcome_launch)
	
	pause_menu = pause_menu_scene.instantiate()
	add_child(pause_menu)
	pause_menu.restart_requested.connect(restart_game)
	pause_menu.briefing_requested.connect(return_to_welcome)
	pause_menu.crt_toggled.connect(func(enabled: bool):
		if crt_layer != null:
			crt_layer.visible = enabled
	)
	
	$player.visible = false
	$player.is_dead = true
	$player.global_position = screen_size / 2.0
	$player.connect("bullet_impact", showBulletImpact)
	$player.connect("fired_projectile", _on_player_fired_projectile)
	$player.connect("ship_destroyed", _on_player_ship_destroyed)
	
	_setup_visual_polish()
	generate_ambient_asteroids(6)

func _setup_visual_polish():
	# 1. Drifting Nebula & Parallax Space Dust
	var nebula = nebula_bg_script.new()
	add_child(nebula)
	nebula.set_player($player)
	
	# 2. Trauma-based Camera Shake
	var cam = camera_shake_script.new()
	add_child(cam)
	
	# 3. HDR Phosphor Glow Environment
	var world_env = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.glow_enabled = true
	env.glow_intensity = 0.65
	env.glow_bloom = 0.25
	env.glow_hdr_threshold = 0.85
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	world_env.environment = env
	add_child(world_env)
	
	# 4. Authentic CRT Scanlines & Vignette Overlay
	crt_layer = CanvasLayer.new()
	crt_layer.layer = 100
	var crt_rect = ColorRect.new()
	crt_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	crt_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat = ShaderMaterial.new()
	mat.shader = crt_shader
	crt_rect.material = mat
	crt_layer.add_child(crt_rect)
	add_child(crt_layer)

func _on_welcome_launch():
	start_game()

func start_game():
	for a in get_tree().get_nodes_in_group("asteroids"):
		a.queue_free()
	_clear_hazards()
		
	game_state = GameState.PLAYING
	if hud != null:
		hud.visible = true
		hud.hide_game_over()
		hud.hide_boss_bar()
		
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
	
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	for b_node in get_tree().get_nodes_in_group("enemy_bullets"):
		b_node.queue_free()
	for pu in get_tree().get_nodes_in_group("powerups"):
		pu.queue_free()
	for a in get_tree().get_nodes_in_group("asteroids"):
		a.queue_free()
	_clear_hazards()
		
	if hud != null:
		hud.visible = false
		hud.hide_game_over()
		hud.hide_boss_bar()
		
	$player.visible = false
	$player.is_dead = true
	
	if welcome_screen != null:
		var hs = score_manager.high_score if score_manager != null else 0
		welcome_screen.reset_to_welcome(hs)
		
	generate_ambient_asteroids(6)

func _input(event):
	if game_state == GameState.PLAYING:
		if event is InputEventKey and event.pressed and not event.is_echo():
			if event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
				if pause_menu != null and not pause_menu.visible:
					pause_menu.open_pause()
					get_viewport().set_input_as_handled()
	elif game_state == GameState.GAME_OVER and can_restart:
		if event is InputEventKey and event.pressed and not event.is_echo():
			if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_R:
				restart_game()
			elif event.keycode == KEY_ESCAPE:
				return_to_welcome()

func _process(delta):
	if game_state == GameState.GAME_OVER:
		if audio_manager != null:
			audio_manager.set_heartbeat(false)
		game_over_return_timer -= delta
		if hud != null:
			hud.set_game_over_countdown(game_over_return_timer)
		if game_over_return_timer <= 0.0:
			return_to_welcome()
		return
		
	if game_state != GameState.PLAYING:
		if audio_manager != null:
			audio_manager.set_heartbeat(false)
		return
		
	if audio_manager != null:
		var remaining_rocks := 0
		for a in get_tree().get_nodes_in_group("asteroids"):
			if is_instance_valid(a) and !a.is_queued_for_deletion() and ("CLONED" in a and !a.CLONED):
				remaining_rocks += 1
		audio_manager.set_heartbeat(remaining_rocks > 0, remaining_rocks)
		
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
		
	if active_mutator == WaveMutator.COMET_TRANSIT:
		if not _has_active_comet():
			comet_spawn_timer -= delta
			if comet_spawn_timer <= 0.0:
				_spawn_comet()
				comet_spawn_timer = rnd.randf_range(5.0, 7.5)

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

func generateAsteroids():
	_clear_hazards()
	var is_boss_wave: bool = (current_wave % 5 == 0)
	var mutator: WaveMutator = WaveMutator.NONE
	if not is_boss_wave and current_wave >= 2:
		var trigger_chance: float = 1.0 if current_wave == 2 else 0.8
		if rnd.randf() <= trigger_chance:
			mutator = _pick_wave_mutator()
	active_mutator = mutator
	
	var sizes = ['lg','md','sm','xs']
	var n = 3 if is_boss_wave else min(10, rnd.randi_range(4, 6) + current_wave - 1)
	var speed_mult: float = 1.65 if active_mutator == WaveMutator.HYPER_DRIFT else 1.0
	
	for i in n:
		var a = asteroidScn.instantiate()
		a.SIZE = sizes[rnd.randi_range(1, 2)] if is_boss_wave else sizes[rnd.randi_range(0,3)]
		a.position = Vector2(rnd.randi_range(0, screen_size.x), rnd.randi_range(0, screen_size.y))
		a.linear_velocity = Vector2(rnd.randi_range(4,16) * randomPosNegOne(), rnd.randi_range(4,16) * randomPosNegOne()) * speed_mult
		a.angular_velocity = (randomPosNegOne() * rnd.randi_range(1,45)) * PI / 180 * speed_mult
		add_child(a)
		a.connect("destroyed", asteroidDestroyed)
		
	if is_boss_wave:
		spawn_boss(max(1, current_wave / 5))
	elif active_mutator != WaveMutator.NONE:
		_activate_mutator(active_mutator)

func _clear_hazards():
	active_mutator = WaveMutator.NONE
	comet_spawn_timer = 0.0
	for h in get_tree().get_nodes_in_group("hazards"):
		if is_instance_valid(h):
			h.queue_free()
	if hud != null and hud.has_method("clear_mutator"):
		hud.clear_mutator()

func _pick_wave_mutator() -> WaveMutator:
	var pool: Array[WaveMutator] = [
		WaveMutator.GRAVITY_WELL,
		WaveMutator.PULSAR_CORE,
		WaveMutator.COMET_TRANSIT,
		WaveMutator.DRONE_SWARM,
		WaveMutator.HYPER_DRIFT,
	]
	if last_mutator in pool and pool.size() > 1:
		pool.erase(last_mutator)
	var chosen: WaveMutator = pool[rnd.randi_range(0, pool.size() - 1)]
	last_mutator = chosen
	return chosen

func _find_safe_hazard_pos(margin: float = 160.0, min_player_dist: float = 220.0) -> Vector2:
	var player_pos: Vector2 = $player.global_position if has_node("player") else screen_size * 0.5
	var best_pos := Vector2(screen_size.x * 0.25, screen_size.y * 0.35)
	for _attempt in range(12):
		var candidate := Vector2(
			rnd.randf_range(margin, max(margin + 20.0, screen_size.x - margin)),
			rnd.randf_range(margin, max(margin + 20.0, screen_size.y - margin))
		)
		if candidate.distance_to(player_pos) >= min_player_dist:
			return candidate
	return best_pos

func _activate_mutator(mutator: WaveMutator):
	var title := ""
	var col := Color(1.0, 0.35, 0.85)
	match mutator:
		WaveMutator.GRAVITY_WELL:
			title = "ANOMALY: GRAVITY WELL"
			col = Color(0.85, 0.3, 1.0)
			var bh = black_hole_scene.instantiate()
			bh.global_position = _find_safe_hazard_pos(170.0, 230.0)
			add_child(bh)
		WaveMutator.PULSAR_CORE:
			title = "ANOMALY: PULSAR CORE"
			col = Color(1.0, 0.25, 0.85)
			var pulsar = pulsar_scene.instantiate()
			pulsar.global_position = _find_safe_hazard_pos(150.0, 220.0)
			add_child(pulsar)
		WaveMutator.COMET_TRANSIT:
			title = "ALERT: COMET TRANSIT"
			col = Color(0.35, 0.92, 1.0)
			comet_spawn_timer = 1.6
		WaveMutator.DRONE_SWARM:
			title = "ALERT: DRONE SWARM"
			col = Color(1.0, 0.6, 0.15)
			var drone_count: int = 2 + min(2, int(current_wave / 3))
			for _i in range(drone_count):
				_spawn_edge_drone()
		WaveMutator.HYPER_DRIFT:
			title = "ANOMALY: HYPER-DRIFT"
			col = Color(1.0, 0.85, 0.2)
	if title != "" and hud != null and hud.has_method("announce_mutator"):
		hud.announce_mutator(title, col)
	audio_manager_script.play_mutator_alert(get_tree())

func _has_active_comet() -> bool:
	for c in get_tree().get_nodes_in_group("comets"):
		if is_instance_valid(c) and !c.is_queued_for_deletion():
			return true
	return false

func _spawn_comet():
	if _has_active_comet():
		return
	var c = comet_scene.instantiate()
	var from_left: bool = rnd.randf() > 0.5
	var start_x: float = -80.0 if from_left else screen_size.x + 80.0
	var end_x: float = screen_size.x + 120.0 if from_left else -120.0
	var start_y: float = rnd.randf_range(80.0, screen_size.y - 80.0)
	var end_y: float = clamp(start_y + rnd.randf_range(-220.0, 220.0), 60.0, screen_size.y - 60.0)
	add_child(c)
	c.setup_transit(Vector2(start_x, start_y), Vector2(end_x, end_y), rnd.randf_range(380.0, 460.0))

func _spawn_edge_drone():
	var d = drone_scene.instantiate()
	var side: int = rnd.randi_range(0, 3)
	var pos := Vector2.ZERO
	match side:
		0:
			pos = Vector2(rnd.randf_range(40.0, screen_size.x - 40.0), -25.0)
		1:
			pos = Vector2(rnd.randf_range(40.0, screen_size.x - 40.0), screen_size.y + 25.0)
		2:
			pos = Vector2(-25.0, rnd.randf_range(40.0, screen_size.y - 40.0))
		_:
			pos = Vector2(screen_size.x + 25.0, rnd.randf_range(40.0, screen_size.y - 40.0))
	d.global_position = pos
	add_child(d)

func spawn_boss(tier: int):
	var b = boss_scene.instantiate()
	b.tier = tier
	b.global_position = Vector2(screen_size.x * 0.5, -50.0)
	add_child(b)
	if hud != null:
		b.boss_hp_changed.connect(hud.update_boss_hp)
		hud.update_boss_hp(b.health, b.max_health, b.boss_name)
	b.boss_defeated.connect(func(_pos, _score_val):
		if hud != null:
			hud.hide_boss_bar()
		call_deferred("_check_wave_cleared")
	)
			
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
	if game_state == GameState.PLAYING and score_manager != null:
		match size:
			'lg': score_manager.add_score(20, pos)
			'md': score_manager.add_score(50, pos)
			'sm': score_manager.add_score(100, pos)
			'xs': score_manager.add_score(150, pos)

	match size:
		'lg':
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
		'md':
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
	vector_shrapnel_script.spawn(self, pos, Color(0.7, 0.95, 0.78), 7, 1.1)
	if game_state == GameState.PLAYING:
		audio_manager_script.play_explosion(get_tree(), false)
		var shake_amt := 0.12
		if size == 'lg':
			shake_amt = 0.28
		elif size == 'md':
			shake_amt = 0.18
		camera_shake_script.shake(get_tree(), shake_amt)
	call_deferred("_check_wave_cleared")

func _check_wave_cleared():
	if game_state != GameState.PLAYING:
		return
	var remaining = 0
	for a in get_tree().get_nodes_in_group("asteroids"):
		if is_instance_valid(a) and !a.is_queued_for_deletion() and ("CLONED" in a and !a.CLONED):
			remaining += 1
	for b in get_tree().get_nodes_in_group("bosses"):
		if is_instance_valid(b) and !b.is_queued_for_deletion():
			remaining += 1
	if remaining == 0:
		audio_manager_script.play_wave_clear(get_tree())
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
	vector_shrapnel_script.spawn(self, pos, Color(0.16, 0.94, 0.0), 10, 1.4)
	camera_shake_script.shake(get_tree(), 0.85)
	
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
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	for b_node in get_tree().get_nodes_in_group("enemy_bullets"):
		b_node.queue_free()
	for pu in get_tree().get_nodes_in_group("powerups"):
		pu.queue_free()
	for a in get_tree().get_nodes_in_group("asteroids"):
		a.queue_free()
	_clear_hazards()
		
	current_wave = 1
	saucer_spawn_timer = 8.0
	if score_manager != null:
		score_manager.reset_game()
	if hud != null:
		hud.visible = true
		hud.hide_game_over()
		hud.hide_boss_bar()
		
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

func showAsteroidExplosion(pos):
	var crash = rock_crash.instantiate()
	crash.global_position = pos
	crash.get_child(0).amount = 50
	crash.get_child(0).lifetime = 2
	crash.get_child(0).speed_scale = 2
	crash.get_child(0).color = Color.WHITE
	add_child(crash)
	crash.get_child(0).emitting = true

