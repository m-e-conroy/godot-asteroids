@tool
extends Control

@export var title_text: String = "NULL SECTOR":
	set(val):
		title_text = val
		queue_redraw()
		update_minimum_size()

@export var subtitle_text: String = "TACTICAL VECTOR DEFENSE // DEEP SPACE INTERCEPT":
	set(val):
		subtitle_text = val
		queue_redraw()

@export var letter_width: float = 34.0:
	set(val):
		letter_width = val
		queue_redraw()
		update_minimum_size()

@export var letter_height: float = 48.0:
	set(val):
		letter_height = val
		queue_redraw()
		update_minimum_size()

@export var letter_spacing: float = 10.0:
	set(val):
		letter_spacing = val
		queue_redraw()
		update_minimum_size()

@export var word_spacing: float = 24.0:
	set(val):
		word_spacing = val
		queue_redraw()
		update_minimum_size()

@export var glow_color: Color = Color(0.16, 0.94, 0.0, 0.4):
	set(val):
		glow_color = val
		queue_redraw()

@export var core_color: Color = Color(0.88, 1.0, 0.88, 1.0):
	set(val):
		core_color = val
		queue_redraw()

var pulse_time: float = 0.0

func _ready():
	update_minimum_size()

func _process(delta: float):
	pulse_time += delta * 2.2
	queue_redraw()

func _get_minimum_size() -> Vector2:
	var total_w = _calculate_title_width()
	return Vector2(max(total_w, 400.0), letter_height + 40.0)

func _calculate_title_width() -> float:
	var w: float = 0.0
	for i in range(title_text.length()):
		var ch = title_text[i]
		if ch == ' ':
			w += word_spacing
		else:
			w += letter_width + (letter_spacing if i < title_text.length() - 1 else 0.0)
	return w

# Vector stroke definitions normalized in [0, 1] x [0, 1]
func _get_glyph_strokes(ch: String) -> Array:
	match ch.to_upper():
		'N':
			return [
				[Vector2(0, 1), Vector2(0, 0), Vector2(1, 1), Vector2(1, 0)]
			]
		'U':
			return [
				[Vector2(0, 0), Vector2(0, 0.75), Vector2(0.25, 1), Vector2(0.75, 1), Vector2(1, 0.75), Vector2(1, 0)]
			]
		'L':
			return [
				[Vector2(0, 0), Vector2(0, 1), Vector2(1, 1)]
			]
		'S':
			return [
				[Vector2(1, 0.15), Vector2(0.8, 0), Vector2(0.2, 0), Vector2(0, 0.2), Vector2(0, 0.45),
				 Vector2(0.2, 0.52), Vector2(0.8, 0.52), Vector2(1, 0.6), Vector2(1, 0.85),
				 Vector2(0.8, 1), Vector2(0.2, 1), Vector2(0, 0.85)]
			]
		'E':
			return [
				[Vector2(1, 0), Vector2(0, 0), Vector2(0, 1), Vector2(1, 1)],
				[Vector2(0, 0.5), Vector2(0.7, 0.5)]
			]
		'C':
			return [
				[Vector2(1, 0.2), Vector2(0.8, 0), Vector2(0.2, 0), Vector2(0, 0.25),
				 Vector2(0, 0.75), Vector2(0.2, 1), Vector2(0.8, 1), Vector2(1, 0.8)]
			]
		'T':
			return [
				[Vector2(0, 0), Vector2(1, 0)],
				[Vector2(0.5, 0), Vector2(0.5, 1)]
			]
		'O':
			return [
				[Vector2(0.25, 0), Vector2(0.75, 0), Vector2(1, 0.25), Vector2(1, 0.75),
				 Vector2(0.75, 1), Vector2(0.25, 1), Vector2(0, 0.75), Vector2(0, 0.25), Vector2(0.25, 0)]
			]
		'R':
			return [
				[Vector2(0, 1), Vector2(0, 0), Vector2(0.75, 0), Vector2(1, 0.25), Vector2(0.75, 0.5), Vector2(0, 0.5)],
				[Vector2(0.5, 0.5), Vector2(1, 1)]
			]
		'-':
			return [
				[Vector2(0.1, 0.5), Vector2(0.9, 0.5)]
			]
		'/':
			return [
				[Vector2(0.1, 1.0), Vector2(0.9, 0.0)]
			]
		_:
			return []

func _draw():
	var total_w = _calculate_title_width()
	var start_x = (size.x - total_w) / 2.0
	var base_y = 6.0
	
	# Breathing harmonic factor
	var pulse = sin(pulse_time)
	var glow_alpha = clamp(0.3 + pulse * 0.12, 0.15, 0.55)
	var dynamic_glow = Color(glow_color.r, glow_color.g, glow_color.b, glow_alpha)
	
	# Subtle cathodic jitter trace
	var jitter_offset = Vector2(sin(pulse_time * 8.0) * 0.35, 0.0)

	var cur_x = start_x
	for i in range(title_text.length()):
		var ch = title_text[i]
		if ch == ' ':
			cur_x += word_spacing
			continue
			
		var strokes = _get_glyph_strokes(ch)
		for stroke in strokes:
			if stroke.size() < 2:
				continue
				
			var points = PackedVector2Array()
			for pt in stroke:
				points.append(Vector2(cur_x + pt.x * letter_width, base_y + pt.y * letter_height))
				
			# 1. Outer phosphor bloom
			draw_polyline(points, dynamic_glow, 4.2, true)
			# 2. Ghost chromatic offset
			var ghost_points = PackedVector2Array()
			for p in points:
				ghost_points.append(p + jitter_offset)
			draw_polyline(ghost_points, Color(dynamic_glow.r, dynamic_glow.g, dynamic_glow.b, dynamic_glow.a * 0.4), 2.2, true)
			# 3. Inner hot razor core
			draw_polyline(points, core_color, 1.6, true)
			
		cur_x += letter_width + letter_spacing

	# Draw Subtitle vector bracket accents and text
	var sub_y = base_y + letter_height + 22.0
	var bracket_w: float = 30.0
	var bracket_margin: float = 12.0
	var text_w: float = total_w * 0.8
	
	var left_bracket_x = (size.x - text_w) / 2.0 - bracket_margin
	var right_bracket_x = (size.x + text_w) / 2.0 + bracket_margin
	
	# Left vector bracket [
	draw_polyline(PackedVector2Array([
		Vector2(left_bracket_x, sub_y - 6.0),
		Vector2(left_bracket_x - bracket_w, sub_y - 6.0),
		Vector2(left_bracket_x - bracket_w, sub_y + 12.0),
		Vector2(left_bracket_x, sub_y + 12.0)
	]), dynamic_glow, 2.0, true)
	
	# Right vector bracket ]
	draw_polyline(PackedVector2Array([
		Vector2(right_bracket_x, sub_y - 6.0),
		Vector2(right_bracket_x + bracket_w, sub_y - 6.0),
		Vector2(right_bracket_x + bracket_w, sub_y + 12.0),
		Vector2(right_bracket_x, sub_y + 12.0)
	]), dynamic_glow, 2.0, true)
	
	# Subtitle font draw
	var default_font = ThemeDB.fallback_font
	if default_font != null and subtitle_text.length() > 0:
		var font_size = 11
		var str_size = default_font.get_string_size(subtitle_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var text_pos = Vector2((size.x - str_size.x) / 2.0, sub_y + 6.0)
		draw_string(default_font, text_pos, subtitle_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(0.25, 0.75, 1.0, 0.85))

