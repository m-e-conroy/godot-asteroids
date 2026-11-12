extends Node2D

const SHIP_SHAPE: Array = [
	Vector2(0, -15),
	Vector2(7, 10),
	Vector2(0, 5),
	Vector2(-7, 10),
	Vector2(0, -15)
]

@export var duration := 1.5
@export var line_color := Color(0.157, 0.941, 0.0, 1.0) # Match ship green

var fragments: Array = []
var elapsed_time := 0.0
var rnd = RandomNumberGenerator.new()

func _ready():
	rnd.randomize()
	# Create line fragment debris from the ship's perimeter
	for i in range(SHIP_SHAPE.size() - 1):
		var p1: Vector2 = SHIP_SHAPE[i]
		var p2: Vector2 = SHIP_SHAPE[i + 1]
		var midpoint: Vector2 = (p1 + p2) / 2.0
		var local_p1: Vector2 = p1 - midpoint
		var local_p2: Vector2 = p2 - midpoint
		
		# Outward trajectory with random deviation
		var outward_dir: Vector2 = midpoint.normalized()
		if outward_dir == Vector2.ZERO:
			outward_dir = Vector2(rnd.randf_range(-1, 1), rnd.randf_range(-1, 1)).normalized()
		var jitter = Vector2(rnd.randf_range(-0.5, 0.5), rnd.randf_range(-0.5, 0.5))
		var vel: Vector2 = (outward_dir + jitter).normalized() * rnd.randf_range(80.0, 180.0)
		
		var rot_speed: float = rnd.randf_range(-7.0, 7.0)
		
		fragments.append({
			"pos": midpoint,
			"vel": vel,
			"p1": local_p1,
			"p2": local_p2,
			"rot": 0.0,
			"rot_speed": rot_speed
		})
	
	if has_node("Particles"):
		$Particles.emitting = true
	if has_node("Boom"):
		$Boom.play()

func _process(delta):
	elapsed_time += delta
	if elapsed_time >= duration:
		queue_free()
		return
		
	for f in fragments:
		f["pos"] += f["vel"] * delta
		f["rot"] += f["rot_speed"] * delta
		f["vel"] *= 0.985 # gentle space deceleration
		
	queue_redraw()

func _draw():
	var alpha: float = clamp(1.0 - (elapsed_time / duration), 0.0, 1.0)
	var color = Color(line_color.r, line_color.g, line_color.b, alpha)
	
	for f in fragments:
		var p1: Vector2 = f["pos"] + f["p1"].rotated(f["rot"])
		var p2: Vector2 = f["pos"] + f["p2"].rotated(f["rot"])
		draw_line(p1, p2, color, 2.0)

