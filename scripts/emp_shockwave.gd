extends Node2D

@export var max_radius: float = 650.0
@export var duration: float = 0.75
@export var damage: int = 5

var current_radius: float = 0.0
var time_alive: float = 0.0
var hit_objects: Array[Node] = []

const COLOR_EMP: Color = Color(0.2, 0.95, 1.0)

func _ready():
	z_index = 10
	var cam_shake = load("res://scripts/camera_shake.gd")
	if cam_shake != null:
		cam_shake.shake(get_tree(), 0.70)
	var am = load("res://scripts/audio_manager.gd")
	if am != null:
		am.play_emp(get_tree())

func _process(delta: float):
	time_alive += delta
	var progress: float = clamp(time_alive / duration, 0.0, 1.0)
	current_radius = ease(progress, 0.35) * max_radius
	
	if time_alive >= duration:
		queue_free()
		return
		
	# Damage and wipe enemies within current radius
	_check_shockwave_targets()
	queue_redraw()

func _check_shockwave_targets():
	# 1. Clear enemy bullets
	var parent_node = get_parent()
	if parent_node == null:
		return
		
	for child in parent_node.get_children():
		if child == self or hit_objects.has(child):
			continue
			
		# Check if child is an enemy bullet or projectile
		if child.is_in_group("enemy_bullets") or child.name.begins_with("saucer_bullet"):
			var dist: float = global_position.distance_to(child.global_position)
			if dist <= current_radius:
				hit_objects.append(child)
				if child.has_method("destroy"):
					child.destroy()
				else:
					child.queue_free()
		# Check if child is enemy (saucer, probe, drone) or asteroid
		elif child.is_in_group("enemies") or child.is_in_group("asteroids") or child.name.begins_with("asteroid") or child.name.begins_with("saucer") or child.name.begins_with("probe") or child.name.begins_with("drone"):
			var dist: float = global_position.distance_to(child.global_position)
			if dist <= current_radius:
				hit_objects.append(child)
				if child.has_method("take_damage"):
					child.take_damage(damage)
				elif child.has_method("take_damange"):
					child.take_damange()

func _draw():
	var progress: float = clamp(time_alive / duration, 0.0, 1.0)
	var alpha: float = (1.0 - progress) * 0.9
	var col = Color(COLOR_EMP.r, COLOR_EMP.g, COLOR_EMP.b, alpha)
	var col_faint = Color(COLOR_EMP.r, COLOR_EMP.g, COLOR_EMP.b, alpha * 0.4)
	
	# Main expanding shockwave ring
	draw_arc(Vector2.ZERO, current_radius, 0.0, 2.0 * PI, 64, col, 3.0)
	
	# Secondary trailing ring
	if current_radius > 30.0:
		draw_arc(Vector2.ZERO, current_radius * 0.82, 0.0, 2.0 * PI, 48, col_faint, 1.5)
	
	# Concentric diamond crosshair lines
	var d_pts: PackedVector2Array = [
		Vector2(0, -current_radius),
		Vector2(current_radius, 0),
		Vector2(0, current_radius),
		Vector2(-current_radius, 0),
		Vector2(0, -current_radius)
	]
	draw_polyline(d_pts, col_faint, 1.5)
	
	# Radial crosshair spikes
	draw_line(Vector2(0, -current_radius * 0.4), Vector2(0, -current_radius * 1.15), col, 2.0)
	draw_line(Vector2(0, current_radius * 0.4), Vector2(0, current_radius * 1.15), col, 2.0)
	draw_line(Vector2(-current_radius * 0.4, 0), Vector2(-current_radius * 1.15, 0), col, 2.0)
	draw_line(Vector2(current_radius * 0.4, 0), Vector2(current_radius * 1.15, 0), col, 2.0)

