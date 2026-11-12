@tool
extends Control

@export var text: String = "000000":
	set(val):
		text = val
		queue_redraw()
		update_minimum_size()

@export var digit_count: int = 6:
	set(val):
		digit_count = val
		queue_redraw()
		update_minimum_size()

@export var digit_width: float = 14.0:
	set(val):
		digit_width = val
		queue_redraw()
		update_minimum_size()

@export var digit_height: float = 24.0:
	set(val):
		digit_height = val
		queue_redraw()
		update_minimum_size()

@export var segment_thickness: float = 2.5:
	set(val):
		segment_thickness = val
		queue_redraw()

@export var spacing: float = 5.0:
	set(val):
		spacing = val
		queue_redraw()
		update_minimum_size()

@export var slant: float = 0.08: # Gentle classic italic slant
	set(val):
		slant = val
		queue_redraw()

@export var color_lit: Color = Color(0.16, 0.94, 0.0, 1.0):
	set(val):
		color_lit = val
		queue_redraw()

@export var color_unlit: Color = Color(0.16, 0.94, 0.0, 0.07):
	set(val):
		color_unlit = val
		queue_redraw()

# Standard 7-segment encoding: [a, b, c, d, e, f, g]
# a=top, b=top-right, c=bottom-right, d=bottom, e=bottom-left, f=top-left, g=center
const SEGMENTS: Dictionary = {
	"0": [true, true, true, true, true, true, false],
	"1": [false, true, true, false, false, false, false],
	"2": [true, true, false, true, true, false, true],
	"3": [true, true, true, true, false, false, true],
	"4": [false, true, true, false, false, true, true],
	"5": [true, false, true, true, false, true, true],
	"6": [true, false, true, true, true, true, true],
	"7": [true, true, true, false, false, false, false],
	"8": [true, true, true, true, true, true, true],
	"9": [true, true, true, true, false, true, true],
	"-": [false, false, false, false, false, false, true],
	" ": [false, false, false, false, false, false, false]
}

func _get_minimum_size() -> Vector2:
	var total_w = digit_count * digit_width + (digit_count - 1) * spacing + (digit_height * slant)
	return Vector2(total_w, digit_height)

func set_number(num: int, leading_zeros: bool = true):
	if leading_zeros:
		var fmt = "%0" + str(digit_count) + "d"
		text = fmt % num
	else:
		text = str(num).lpad(digit_count, " ")

func _draw():
	# Format string padded to digit_count
	var disp_str = text
	if disp_str.length() < digit_count:
		disp_str = disp_str.lpad(digit_count, "0")
	elif disp_str.length() > digit_count:
		disp_str = disp_str.substr(disp_str.length() - digit_count, digit_count)
		
	var cur_x: float = 0.0
	for i in range(disp_str.length()):
		var ch = disp_str[i]
		_draw_digit(cur_x, ch)
		cur_x += digit_width + spacing

func _draw_digit(start_x: float, ch: String):
	var seg_active = SEGMENTS.get(ch, SEGMENTS[" "])
	var w = digit_width
	var h = digit_height
	var mid_y = h / 2.0
	var t = segment_thickness
	var half_t = t / 2.0
	
	# Helper lambda to apply italic slant
	var pt = func(lx: float, ly: float) -> Vector2:
		var slanted_x = start_x + lx + (h - ly) * slant
		return Vector2(slanted_x, ly)

	# Segment definitions (trapezoid/hexagon points)
	# a: Top horizontal
	var pts_a = PackedVector2Array([
		pt.call(half_t, 0),
		pt.call(w - half_t, 0),
		pt.call(w - t, t),
		pt.call(t, t)
	])
	
	# b: Top-right vertical
	var pts_b = PackedVector2Array([
		pt.call(w, half_t),
		pt.call(w, mid_y - half_t),
		pt.call(w - t, mid_y - t * 0.7),
		pt.call(w - t, t)
	])
	
	# c: Bottom-right vertical
	var pts_c = PackedVector2Array([
		pt.call(w, mid_y + half_t),
		pt.call(w, h - half_t),
		pt.call(w - t, h - t),
		pt.call(w - t, mid_y + t * 0.7)
	])
	
	# d: Bottom horizontal
	var pts_d = PackedVector2Array([
		pt.call(half_t, h),
		pt.call(w - half_t, h),
		pt.call(w - t, h - t),
		pt.call(t, h - t)
	])
	
	# e: Bottom-left vertical
	var pts_e = PackedVector2Array([
		pt.call(0, mid_y + half_t),
		pt.call(0, h - half_t),
		pt.call(t, h - t),
		pt.call(t, mid_y + t * 0.7)
	])
	
	# f: Top-left vertical
	var pts_f = PackedVector2Array([
		pt.call(0, half_t),
		pt.call(0, mid_y - half_t),
		pt.call(t, mid_y - t * 0.7),
		pt.call(t, t)
	])
	
	# g: Middle horizontal
	var pts_g = PackedVector2Array([
		pt.call(t, mid_y),
		pt.call(half_t + t * 0.5, mid_y - half_t),
		pt.call(w - half_t - t * 0.5, mid_y - half_t),
		pt.call(w - t, mid_y),
		pt.call(w - half_t - t * 0.5, mid_y + half_t),
		pt.call(half_t + t * 0.5, mid_y + half_t)
	])

	var all_segs = [pts_a, pts_b, pts_c, pts_d, pts_e, pts_f, pts_g]
	for s_idx in range(7):
		var is_lit = seg_active[s_idx]
		var col = color_lit if is_lit else color_unlit
		draw_colored_polygon(all_segs[s_idx], col)

