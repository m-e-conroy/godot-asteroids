extends CharacterBody2D

signal boss_hp_changed(hp: int, max_hp: int, boss_name: String)
signal boss_defeated(pos: Vector2, score_val: int)

enum AttackType { RADIAL_SPIRAL, AIMED_VOLLEY, DEPLOY_ESCORT, SWEEP_LANCE }

@export var tier: int = 1

var boss_name: String = "OMEGA DREADNOUGHT MK-I"
var max_health: int = 20
var health: int = 20
var score_value: int = 1500
var hull_radius: float = 42.0
var symmetry: int = 4
var hull_color: Color = Color(1.0, 0.22, 0.3)
var core_color: Color = Color(0.25, 0.85, 1.0)

var outer_points: PackedVector2Array = PackedVector2Array()
var inner_points: PackedVector2Array = PackedVector2Array()
var shield_arcs: int = 2

var attack_deck: Array = []
var current_attack_idx: int = 0
var attack_timer: float = 2.0
var attack_interval: float = 2.2

var spiral_angle: float = 0.0
var patrol_time: float = 0.0
var hit_flash_timer: float = 0.0
var lance_telegraph_timer: float = 0.0
var lance_dir: Vector2 = Vector2.DOWN

var enemy_bullet_scene = preload("res://Enemies/Saucer/saucer_bullet.tscn")
var drone_scene = preload("res://Enemies/Drone/drone.tscn")
var probe_scene = preload("res://Enemies/Probe/probe.tscn")
var powerup_scene = preload("res://Pickups/powerup.tscn")
var rock_crash_scene = preload("res://effects/rock_crash.tscn")
var explosion_sound = preload("res://sounds/explosion.wav")

@onready var screen_size: Vector2 = get_viewport_rect().size
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	add_to_group("enemies")
	add_to_group("bosses")
	collision_layer = 2
	collision_mask = 1
	
	_generate_from_rules()
	
	# Setup collision radius matching generated hull
	if collision_shape != null:
		var circle = CircleShape2D.new()
		circle.radius = hull_radius * 0.85
		collision_shape.shape = circle
		
	boss_hp_changed.emit(health, max_health, boss_name)

func _generate_from_rules():
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	# 1. Scaling Rules
	max_health = 20 + (tier - 1) * 15
	health = max_health
	score_value = 1500 * tier
	hull_radius = 40.0 + min(tier - 1, 4) * 6.0
	attack_interval = max(1.05, 2.4 - (tier - 1) * 0.25)
	attack_timer = 1.6
	
	# 2. Color & Name Rules
	var tier_colors = [
		Color(1.0, 0.22, 0.30), # Crimson
		Color(1.0, 0.72, 0.15), # Amber
		Color(0.80, 0.28, 1.00), # Amethyst
		Color(0.25, 0.90, 1.00), # Electric Cyan
	]
	hull_color = tier_colors[(tier - 1) % tier_colors.size()]
	
	var prefixes = ["OMEGA", "VOID", "APEX", "VORTEX", "HYPER", "NULL"]
	var nouns = ["DREADNOUGHT", "LEVIATHAN", "CITADEL", "MONOLITH", "WARDEN"]
	var romans = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]
	var mk = romans[clamp(tier - 1, 0, romans.size() - 1)]
	boss_name = "%s %s MK-%s" % [prefixes[rng.randi_range(0, prefixes.size() - 1)], nouns[rng.randi_range(0, nouns.size() - 1)], mk]
	
	# 3. Procedural Hull Geometry Rules
	var sym_choices = [3, 4, 5, 6, 8]
	symmetry = sym_choices[rng.randi_range(0, min(tier + 1, sym_choices.size() - 1))]
	shield_arcs = clamp(tier, 1, 4)
	
	var spike_ratio = rng.randf_range(0.55, 0.85)
	outer_points.clear()
	inner_points.clear()
	var total_pts = symmetry * 2
	for i in range(total_pts + 1):
		var a = float(i) * (TAU / float(total_pts))
		var r = hull_radius if (i % 2 == 0) else (hull_radius * spike_ratio)
		outer_points.append(Vector2(cos(a), sin(a)) * r)
		
	for i in range(symmetry + 1):
		var a = float(i) * (TAU / float(symmetry))
		inner_points.append(Vector2(cos(a), sin(a)) * (hull_radius * 0.42))
		
	# 4. Attack Pattern Deck Rules
	attack_deck.clear()
	attack_deck.append(AttackType.RADIAL_SPIRAL)
	attack_deck.append(AttackType.AIMED_VOLLEY)
	if tier >= 1:
		attack_deck.append(AttackType.DEPLOY_ESCORT)
	if tier >= 2:
		attack_deck.append(AttackType.SWEEP_LANCE)

func _physics_process(delta: float):
	patrol_time += delta
	if hit_flash_timer > 0.0:
		hit_flash_timer -= delta
		
	# Smoothly patrol in an upper-mid figure-eight arc
	var target_x = screen_size.x * 0.5 + sin(patrol_time * (0.45 + tier * 0.05)) * (screen_size.x * 0.30)
	var target_y = 145.0 + sin(patrol_time * 0.9) * 45.0
	var target_pos = Vector2(target_x, target_y)
	
	var move_dir = target_pos - global_position
	var speed = min(move_dir.length() * 2.2, 110.0 + tier * 15.0)
	velocity = move_dir.normalized() * speed if move_dir.length() > 2.0 else Vector2.ZERO
	move_and_slide()
	
	# Check direct collision with player
	for i in range(get_slide_collision_count()):
		var col = get_slide_collision(i)
		var body = col.get_collider()
		if body != null and (body.is_in_group("player") or body.name == "player"):
			if body.has_method("take_damage"):
				body.take_damage(100.0)
				
	# Telegraph handling for Lance attack
	if lance_telegraph_timer > 0.0:
		lance_telegraph_timer -= delta
		if lance_telegraph_timer <= 0.0:
			_fire_lance_burst()
			
	# Attack sequencing
	attack_timer -= delta
	if attack_timer <= 0.0:
		attack_timer = attack_interval
		_execute_next_attack()
		
	queue_redraw()

func _execute_next_attack():
	if attack_deck.is_empty():
		return
	var atk = attack_deck[current_attack_idx]
	current_attack_idx = (current_attack_idx + 1) % attack_deck.size()
	
	match atk:
		AttackType.RADIAL_SPIRAL:
			var count = 6 + tier * 2
			spiral_angle += 0.35
			for i in range(count):
				var dir = Vector2.RIGHT.rotated(spiral_angle + i * (TAU / float(count)))
				_spawn_bullet(global_position + dir * (hull_radius * 0.8), dir, 175.0 + tier * 15.0)
		AttackType.AIMED_VOLLEY:
			var player = get_tree().get_first_node_in_group("player")
			var base_dir = Vector2.DOWN
			if player != null and is_instance_valid(player):
				base_dir = (player.global_position - global_position).normalized()
			var spread_count = 3 if tier == 1 else 5
			var half = spread_count / 2
			for i in range(-half, half + 1):
				var dir = base_dir.rotated(i * 0.18)
				_spawn_bullet(global_position + dir * (hull_radius * 0.85), dir, 220.0 + tier * 15.0)
		AttackType.DEPLOY_ESCORT:
			var existing = get_tree().get_nodes_in_group("enemies").size() - 1
			if existing < (2 + tier):
				var spawn_pos = global_position + Vector2(randf_range(-40, 40), 40)
				var escort = drone_scene.instantiate() if randf() > 0.45 else probe_scene.instantiate()
				escort.global_position = spawn_pos
				get_parent().add_child(escort)
		AttackType.SWEEP_LANCE:
			var player = get_tree().get_first_node_in_group("player")
			lance_dir = Vector2.DOWN
			if player != null and is_instance_valid(player):
				lance_dir = (player.global_position - global_position).normalized()
			lance_telegraph_timer = 0.8

func _fire_lance_burst():
	for i in range(4):
		var dir = lance_dir.rotated((i - 1.5) * 0.04)
		_spawn_bullet(global_position + dir * hull_radius, dir, 310.0)

func _spawn_bullet(pos: Vector2, dir: Vector2, spd: float):
	var parent_node = get_parent()
	if parent_node == null or enemy_bullet_scene == null:
		return
	var b = enemy_bullet_scene.instantiate()
	b.global_position = pos
	b.velocity = dir * spd
	b.rotation = dir.angle() + PI / 2.0
	parent_node.add_child(b)

func take_damage(amount: int = 1):
	if is_queued_for_deletion():
		return
	health -= amount
	hit_flash_timer = 0.09
	boss_hp_changed.emit(max(0, health), max_health, boss_name)
	if health <= 0:
		destroy()

func take_damange():
	take_damage(1)

func takeDamange():
	take_damage(1)

func destroy():
	if is_queued_for_deletion():
		return
		
	var parent_node = get_parent()
	if parent_node != null:
		var sm = get_tree().get_first_node_in_group("score_manager")
		if sm != null:
			sm.add_score(score_value, global_position)
			
		# Explosion SFX
		var sfx = AudioStreamPlayer2D.new()
		sfx.stream = explosion_sound
		sfx.volume_db = -1.0
		sfx.global_position = global_position
		parent_node.add_child(sfx)
		sfx.play()
		sfx.finished.connect(sfx.queue_free)
		
		# Massive Shrapnel & Camera Shake
		var shrapnel = load("res://effects/vector_shrapnel.gd")
		if shrapnel != null:
			shrapnel.spawn(parent_node, global_position, hull_color, 18, 1.8)
		var cam_shake = load("res://scripts/camera_shake.gd")
		if cam_shake != null:
			cam_shake.shake(get_tree(), 0.95)
			
		# Particle burst
		var crash = rock_crash_scene.instantiate()
		crash.global_position = global_position
		var emitter = crash.get_child(0)
		emitter.amount = 70
		emitter.lifetime = 1.6
		emitter.color = hull_color
		parent_node.add_child(crash)
		emitter.emitting = true
		
		# Guaranteed 2 Power-Up Drops
		for i in range(2):
			var pu = powerup_scene.instantiate()
			pu.global_position = global_position + Vector2(-24 + i * 48, 0)
			pu.type = randi() % 4
			parent_node.add_child(pu)
			
	boss_defeated.emit(global_position, score_value)
	queue_free()

func _draw():
	var draw_col = Color.WHITE if hit_flash_timer > 0.0 else hull_color
	var rot_hull = patrol_time * 0.45
	
	# 1. Telegraph Lance Line
	if lance_telegraph_timer > 0.0:
		var blink = 0.4 + 0.5 * abs(sin(patrol_time * 24.0))
		draw_line(Vector2.ZERO, lance_dir * 750.0, Color(1.0, 0.2, 0.2, blink), 2.0)
		
	# 2. Rotating Shield Arcs
	var shield_r = hull_radius + 14.0
	var arc_span = TAU / float(shield_arcs * 2)
	for i in range(shield_arcs):
		var a_start = -patrol_time * 1.1 + i * (TAU / float(shield_arcs))
		draw_arc(Vector2.ZERO, shield_r, a_start, a_start + arc_span, 12, Color(core_color.r, core_color.g, core_color.b, 0.65), 2.5)
		
	# 3. Outer Hull Polygon
	var rot_outer = PackedVector2Array()
	for pt in outer_points:
		rot_outer.append(pt.rotated(rot_hull))
	draw_polyline(rot_outer, Color(draw_col.r, draw_col.g, draw_col.b, 0.35), 5.0, true)
	draw_polyline(rot_outer, draw_col, 2.2, true)
	
	# 4. Inner Core Polygon
	var rot_inner = PackedVector2Array()
	for pt in inner_points:
		rot_inner.append(pt.rotated(-rot_hull * 1.5))
	draw_polyline(rot_inner, core_color, 1.8, true)
	draw_circle(Vector2.ZERO, 6.0 + sin(patrol_time * 6.0) * 2.0, Color.WHITE)

