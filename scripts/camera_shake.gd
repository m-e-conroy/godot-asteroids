extends Camera2D

@export var trauma_decay: float = 2.4
@export var max_offset: Vector2 = Vector2(16.0, 12.0)
@export var max_roll: float = 0.02

var trauma: float = 0.0
var base_position: Vector2 = Vector2.ZERO
var noise_seed: float = 0.0

func _ready():
	add_to_group("camera_shake")
	ignore_rotation = false
	base_position = get_viewport_rect().size / 2.0
	position = base_position

static func shake(tree: SceneTree, amount: float):
	if tree == null:
		return
	var cam = tree.get_first_node_in_group("camera_shake")
	if cam != null and cam.has_method("add_trauma"):
		cam.add_trauma(amount)

func add_trauma(amount: float):
	trauma = clamp(trauma + amount, 0.0, 1.0)

func _process(delta: float):
	if trauma > 0.0:
		trauma = max(0.0, trauma - trauma_decay * delta)
		_apply_shake(delta)
	else:
		offset = Vector2.ZERO
		rotation = 0.0

func _apply_shake(delta: float):
	noise_seed += delta * 55.0
	var amount: float = trauma * trauma
	offset.x = max_offset.x * amount * sin(noise_seed * 1.3 + cos(noise_seed * 0.7))
	offset.y = max_offset.y * amount * cos(noise_seed * 1.7 + sin(noise_seed * 0.9))
	rotation = max_roll * amount * sin(noise_seed * 2.1)

