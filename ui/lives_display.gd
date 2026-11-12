@tool
extends Control

@onready var hud = get_node("/root/Node2D/HUD") if not Engine.is_editor_hint() else null

const SHIP_SHAPE: PackedVector2Array = [
	Vector2(0, -9),
	Vector2(5, 7),
	Vector2(0, 3.5),
	Vector2(-5, 7),
	Vector2(0, -9)
]

func _get_minimum_size() -> Vector2:
	return Vector2(90, 24)

func _draw():
	var lives_cnt = 3
	if hud != null and "current_lives" in hud:
		lives_cnt = hud.current_lives
	else:
		# Fallback checking parent
		var p = get_parent()
		while p != null:
			if "current_lives" in p:
				lives_cnt = p.current_lives
				break
			p = p.get_parent()
			
	var col = Color(0.16, 0.94, 0.0)
	for i in range(max(0, lives_cnt)):
		var center = Vector2(i * 18.0 + 10.0, 12.0)
		var pts = PackedVector2Array()
		for pt in SHIP_SHAPE:
			pts.append(center + pt)
		draw_polyline(pts, col, 1.5)

