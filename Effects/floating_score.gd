extends Node2D

var text_str: String = "+100"
var text_color: Color = Color(0.16, 0.94, 0.0)
var time_alive: float = 0.0
var lifetime: float = 0.85
var velocity: Vector2 = Vector2(0.0, -38.0)

static func spawn(tree: SceneTree, pos: Vector2, points: int, combo: int = 1, col: Color = Color(0.16, 0.94, 0.0)):
	if tree == null or tree.current_scene == null:
		return
	var node = load("res://effects/floating_score.gd").new()
	node.global_position = pos + Vector2(randf_range(-10.0, 10.0), -10.0)
	if combo > 1:
		node.text_str = "+%d x%d" % [points, combo]
		node.text_color = Color(1.0, 0.85, 0.2) if combo < 5 else Color(1.0, 0.3, 0.8)
	else:
		node.text_str = "+%d" % points
		node.text_color = col
	tree.current_scene.add_child(node)

func _ready():
	z_index = 40

func _process(delta: float):
	time_alive += delta
	if time_alive >= lifetime:
		queue_free()
		return
	position += velocity * delta
	velocity *= exp(-1.5 * delta)
	queue_redraw()

func _draw():
	var font = ThemeDB.fallback_font
	if font == null:
		return
	var t = clamp(time_alive / lifetime, 0.0, 1.0)
	var alpha = 1.0 - (t * t)
	var font_size = 13 if "x" not in text_str else 15
	var sz = font.get_string_size(text_str, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var draw_pos = Vector2(-sz.x / 2.0, 0.0)
	draw_string(font, draw_pos, text_str, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(text_color.r, text_color.g, text_color.b, alpha))

