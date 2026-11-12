extends Node2D

var shards: Array = []
var lifetime: float = 0.9
var time_alive: float = 0.0
var base_color: Color = Color(0.16, 0.94, 0.0)

static func spawn(parent: Node, pos: Vector2, col: Color = Color.WHITE, count: int = 7, speed_scale: float = 1.0):
	if parent == null:
		return
	var node = load("res://effects/vector_shrapnel.gd").new()
	node.global_position = pos
	node.base_color = col
	node._init_shards(count, speed_scale)
	parent.add_child(node)

func _init_shards(count: int, speed_scale: float):
	shards.clear()
	for i in range(count):
		var angle = randf() * TAU
		var speed = randf_range(55.0, 175.0) * speed_scale
		var half_len = randf_range(5.0, 14.0) * clamp(speed_scale, 0.7, 1.5)
		shards.append({
			"pos": Vector2.ZERO,
			"vel": Vector2.RIGHT.rotated(angle) * speed,
			"rot": randf() * TAU,
			"rot_speed": randf_range(-9.0, 9.0),
			"half_len": half_len,
			"life": randf_range(0.6, 1.05)
		})

func _process(delta: float):
	time_alive += delta
	var any_alive := false
	for s in shards:
		if time_alive < s["life"]:
			any_alive = true
			s["pos"] += s["vel"] * delta
			s["vel"] *= exp(-1.8 * delta)
			s["rot"] += s["rot_speed"] * delta
			
	if not any_alive or time_alive >= 1.1:
		queue_free()
		return
		
	queue_redraw()

func _draw():
	for s in shards:
		if time_alive >= s["life"]:
			continue
		var t = 1.0 - (time_alive / s["life"])
		var alpha = t * t
		var dir = Vector2.RIGHT.rotated(s["rot"]) * s["half_len"]
		var p1 = s["pos"] - dir
		var p2 = s["pos"] + dir
		
		# Outer phosphor glow + bright core
		draw_line(p1, p2, Color(base_color.r, base_color.g, base_color.b, alpha * 0.45), 3.2)
		draw_line(p1, p2, Color(1.0, 1.0, 1.0, alpha * 0.9), 1.4)

