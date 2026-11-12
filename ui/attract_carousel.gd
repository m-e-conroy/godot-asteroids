@tool
extends Control

signal card_changed(card_index: int)

enum Card { THREATS, CONTROLS, UPGRADES }

@export var current_card: Card = Card.THREATS:
	set(val):
		current_card = val
		transition_alpha = 0.0
		queue_redraw()
		card_changed.emit(current_card)

@export var auto_cycle_time: float = 6.0
@export var show_nav_pips: bool = true

var timer: float = 0.0
var anim_time: float = 0.0
var transition_alpha: float = 1.0

# Color Tokens
const COLOR_GREEN: Color = Color(0.16, 0.94, 0.0)
const COLOR_WHITE_CORE: Color = Color(0.88, 1.0, 0.88)
const COLOR_CYAN: Color = Color(0.25, 0.75, 1.0)
const COLOR_GOLD: Color = Color(1.0, 0.8, 0.15)
const COLOR_AMETHYST: Color = Color(0.77, 0.25, 1.0)
const COLOR_RED: Color = Color(1.0, 0.25, 0.25)

func _ready():
	timer = 0.0
	transition_alpha = 1.0

func _process(delta: float):
	anim_time += delta
	timer += delta
	
	if transition_alpha < 1.0:
		transition_alpha = min(1.0, transition_alpha + delta * 3.5)
		
	if auto_cycle_time > 0.0 and timer >= auto_cycle_time:
		timer = 0.0
		next_card()
		
	queue_redraw()

func next_card():
	timer = 0.0
	current_card = ((current_card + 1) % 3) as Card

func prev_card():
	timer = 0.0
	current_card = ((current_card + 2) % 3) as Card

func _gui_input(event: InputEvent):
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_RIGHT or event.keycode == KEY_D or event.keycode == KEY_TAB:
			next_card()
			accept_event()
		elif event.keycode == KEY_LEFT or event.keycode == KEY_A:
			prev_card()
			accept_event()

func _draw():
	var center = size / 2.0
	var font = ThemeDB.fallback_font
	
	# Draw active card contents
	match current_card:
		Card.THREATS:
			_draw_threat_dossier(center, font)
		Card.CONTROLS:
			_draw_flight_manual(center, font)
		Card.UPGRADES:
			_draw_upgrades_arsenal(center, font)
			
	# Draw navigation pips and card switcher at bottom
	if show_nav_pips:
		_draw_navigation_pips(center, font)

# ==============================================================================
# CARD 1: THREAT & SCORING DOSSIER
# ==============================================================================
func _draw_threat_dossier(center: Vector2, font: Font):
	var title_text = "--- SECTOR THREAT DOSSIER & BOUNTIES ---"
	if font != null:
		var t_size = font.get_string_size(title_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14)
		draw_string(font, Vector2(center.x - t_size.x / 2.0, 24.0), title_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, COLOR_CYAN)

	var col1_x = center.x - 220.0
	var col2_x = center.x + 80.0
	var start_y = 65.0
	var row_h = 38.0

	# Left Column: Asteroids
	_draw_dossier_item(Vector2(col1_x, start_y), "LARGE ASTEROID", "20 PTS", COLOR_GREEN, font, "ast_lg")
	_draw_dossier_item(Vector2(col1_x, start_y + row_h), "MEDIUM ASTEROID", "50 PTS", COLOR_GREEN, font, "ast_md")
	_draw_dossier_item(Vector2(col1_x, start_y + row_h * 2), "SMALL ASTEROID", "100 PTS", COLOR_GREEN, font, "ast_sm")
	_draw_dossier_item(Vector2(col1_x, start_y + row_h * 3), "EXTRA SMALL ROCK", "150 PTS", COLOR_GREEN, font, "ast_xs")

	# Right Column: Enemies & Saucers
	_draw_dossier_item(Vector2(col2_x, start_y), "SENTRY PROBE", "150 PTS", COLOR_AMETHYST, font, "probe")
	_draw_dossier_item(Vector2(col2_x, start_y + row_h), "HUNTER DRONE", "250 PTS", COLOR_GOLD, font, "drone")
	_draw_dossier_item(Vector2(col2_x, start_y + row_h * 2), "ALIEN SAUCER", "300 PTS", COLOR_RED, font, "saucer")
	_draw_dossier_item(Vector2(col2_x, start_y + row_h * 3), "TACTICAL PICKUP", "100 PTS", COLOR_CYAN, font, "pickup")

	# Bottom Bonus Life Banner
	var pulse = 0.6 + sin(anim_time * 4.0) * 0.4
	var bonus_text = "★ EXTRA SHIP AWARDED EVERY 10,000 POINTS ★"
	if font != null:
		var b_size = font.get_string_size(bonus_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 13)
		draw_string(font, Vector2(center.x - b_size.x / 2.0, start_y + row_h * 4 + 18.0), bonus_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 13, Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, pulse))

func _draw_dossier_item(pos: Vector2, name_str: String, score_str: String, col: Color, font: Font, icon_type: String):
	# Draw vector mini-icon at pos
	_draw_mini_icon(pos + Vector2(16.0, 0.0), icon_type, col)
	
	if font != null:
		draw_string(font, pos + Vector2(40.0, 5.0), name_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
		draw_string(font, pos + Vector2(190.0, 5.0), score_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, col)

func _draw_mini_icon(pos: Vector2, icon_type: String, col: Color):
	var rot = anim_time * 0.8
	match icon_type:
		"ast_lg":
			_draw_polygon_outline(pos, 12.0, 7, col, rot)
		"ast_md":
			_draw_polygon_outline(pos, 9.0, 6, col, -rot)
		"ast_sm":
			_draw_polygon_outline(pos, 7.0, 5, col, rot * 1.2)
		"ast_xs":
			_draw_polygon_outline(pos, 5.0, 4, col, -rot * 1.5)
		"probe":
			# Rotating Amethyst Octahedron
			var pts = PackedVector2Array()
			for i in range(5):
				var a = rot * 1.5 + i * (PI / 2.0)
				pts.append(pos + Vector2(cos(a), sin(a)) * 10.0)
			draw_polyline(pts, col, 1.5, true)
			draw_circle(pos, 2.5, Color.WHITE)
		"drone":
			# Amber Delta Fighter
			var front = pos + Vector2(0, -9).rotated(rot)
			var left = pos + Vector2(-8, 8).rotated(rot)
			var right = pos + Vector2(8, 8).rotated(rot)
			var back = pos + Vector2(0, 4).rotated(rot)
			draw_polyline(PackedVector2Array([front, left, back, right, front]), col, 1.5, true)
		"saucer":
			# Saucer ellipse and dome
			draw_arc(pos, 10.0, 0, TAU, 12, col, 1.5)
			draw_arc(pos + Vector2(0, -3), 4.5, PI, TAU, 8, COLOR_CYAN, 1.5)
			draw_line(pos + Vector2(-10, 0), pos + Vector2(10, 0), col, 1.5)
		"pickup":
			# Diamond with inner dot
			var pts = PackedVector2Array([
				pos + Vector2(0, -8), pos + Vector2(8, 0), pos + Vector2(0, 8), pos + Vector2(-8, 0), pos + Vector2(0, -8)
			])
			draw_polyline(pts, col, 1.5, true)
			draw_circle(pos, 2.0, Color.WHITE)

func _draw_polygon_outline(pos: Vector2, radius: float, sides: int, col: Color, angle_offset: float):
	var pts = PackedVector2Array()
	for i in range(sides + 1):
		var a = angle_offset + i * (TAU / sides)
		var r = radius * (0.85 if i % 2 == 1 else 1.0)
		pts.append(pos + Vector2(cos(a), sin(a)) * r)
	draw_polyline(pts, col, 1.5, true)

# ==============================================================================
# CARD 2: COMBAT & FLIGHT SYSTEMS MANUAL
# ==============================================================================
func _draw_flight_manual(center: Vector2, font: Font):
	var title_text = "--- SHIP AVIONICS & TACTICAL FLIGHT MANUAL ---"
	if font != null:
		var t_size = font.get_string_size(title_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14)
		draw_string(font, Vector2(center.x - t_size.x / 2.0, 24.0), title_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, COLOR_CYAN)

	var ship_pos = center + Vector2(0.0, -10.0)
	
	# Draw Enlarged Player Wireframe Ship Blueprint
	var s_scale = 1.9
	var nose = ship_pos + Vector2(0, -22) * s_scale
	var left_wing = ship_pos + Vector2(-15, 16) * s_scale
	var right_wing = ship_pos + Vector2(15, 16) * s_scale
	var rear_indent = ship_pos + Vector2(0, 10) * s_scale
	
	# Force field wireframe halo around ship
	var shield_pulse = 0.5 + sin(anim_time * 3.0) * 0.25
	draw_arc(ship_pos, 46.0, 0, TAU, 28, Color(COLOR_CYAN.r, COLOR_CYAN.g, COLOR_CYAN.b, shield_pulse), 1.5)
	
	# Ship Hull
	draw_polyline(PackedVector2Array([nose, left_wing, rear_indent, right_wing, nose]), COLOR_GREEN, 2.0, true)
	draw_polyline(PackedVector2Array([nose, rear_indent]), Color(COLOR_GREEN.r, COLOR_GREEN.g, COLOR_GREEN.b, 0.4), 1.0, true)

	# Callout 1: Laser Cannons (Top)
	_draw_callout_bracket(nose, nose + Vector2(0, -32), "[SPACEBAR]  TWIN PULSE CANNONS", COLOR_WHITE_CORE, font, true)

	# Callout 2: Inertial Thrusters (Bottom)
	_draw_callout_bracket(rear_indent, rear_indent + Vector2(0, 36), "[W] or [▲]  INERTIAL MAIN THRUSTER", COLOR_GOLD, font, false)

	# Callout 3: Gyro Steering (Left & Right)
	_draw_callout_bracket(left_wing, left_wing + Vector2(-120, 0), "[A] or [◄]  ROTATE PORT", COLOR_GREEN, font, false, HORIZONTAL_ALIGNMENT_RIGHT)
	_draw_callout_bracket(right_wing, right_wing + Vector2(120, 0), "[D] or [►]  ROTATE STBD", COLOR_GREEN, font, false, HORIZONTAL_ALIGNMENT_LEFT)

	# Callout 4: Force Field Shield
	var shield_label_pos = center + Vector2(0, 100.0)
	if font != null:
		var s_text = "[S] or [▼]  DEFLECTOR FORCE FIELD // 4.0s BARRIER (12s RECHARGE)"
		var s_sz = font.get_string_size(s_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 12)
		draw_string(font, Vector2(center.x - s_sz.x / 2.0, shield_label_pos.y), s_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 12, COLOR_CYAN)

func _draw_callout_bracket(from_pt: Vector2, to_pt: Vector2, text: String, col: Color, font: Font, above: bool = false, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER):
	# Leader line
	draw_line(from_pt, to_pt, Color(col.r, col.g, col.b, 0.6), 1.2)
	draw_circle(from_pt, 2.5, col)
	
	if font != null:
		var text_sz = font.get_string_size(text, align, -1, 11)
		var text_pos: Vector2
		if align == HORIZONTAL_ALIGNMENT_RIGHT:
			text_pos = to_pt + Vector2(-text_sz.x - 8.0, 4.0)
		elif align == HORIZONTAL_ALIGNMENT_LEFT:
			text_pos = to_pt + Vector2(8.0, 4.0)
		else:
			text_pos = to_pt + Vector2(-text_sz.x / 2.0, -8.0 if above else 16.0)
		draw_string(font, text_pos, text, align, -1, 11, col)

# ==============================================================================
# CARD 3: TACTICAL POWER-UP ARSENAL
# ==============================================================================
func _draw_upgrades_arsenal(center: Vector2, font: Font):
	var title_text = "--- TACTICAL BATTLEFIELD ORDNANCE & POWER-UPS ---"
	if font != null:
		var t_size = font.get_string_size(title_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14)
		draw_string(font, Vector2(center.x - t_size.x / 2.0, 24.0), title_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, COLOR_CYAN)

	var items = [
		{
			"title": "TRIPLE SHOT // SPREAD FIRE",
			"desc": "Splits laser output across port, starboard, and bow mounts (10.0s)",
			"color": COLOR_GOLD,
			"icon": "triple"
		},
		{
			"title": "RAPID FIRE // PLASMA STREAM",
			"desc": "Accelerates laser capacitor recharge to 0.12s continuous fire (10.0s)",
			"color": Color(1.0, 0.25, 0.8),
			"icon": "rapid"
		},
		{
			"title": "EMP SHOCKWAVE // AREA NUKE",
			"desc": "Emits an expanding 600px radial electromagnetic wipe destroying all targets",
			"color": COLOR_CYAN,
			"icon": "emp"
		},
		{
			"title": "SHIELD OVERCHARGE // REPAIR",
			"desc": "Instantly resets Force Field cooldown and restores barrier to 100% READY",
			"color": COLOR_GREEN,
			"icon": "shield"
		}
	]

	var start_y = 65.0
	var card_w = 480.0
	var row_h = 42.0

	for i in range(items.size()):
		var item = items[i]
		var y = start_y + i * row_h
		var box_x = center.x - card_w / 2.0
		
		# Miniature Vector Icon
		var icon_pos = Vector2(box_x + 24.0, y + 14.0)
		_draw_powerup_icon(icon_pos, item["icon"], item["color"])
		
		if font != null:
			draw_string(font, Vector2(box_x + 58.0, y + 10.0), item["title"], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, item["color"])
			draw_string(font, Vector2(box_x + 58.0, y + 26.0), item["desc"], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.85, 0.85, 0.85, 0.8))

func _draw_powerup_icon(pos: Vector2, icon_type: String, col: Color):
	var rot = anim_time * 1.5
	match icon_type:
		"triple":
			# Radiating triple daggers
			draw_polyline(PackedVector2Array([pos + Vector2(0, -9), pos + Vector2(-3, -2), pos + Vector2(3, -2), pos + Vector2(0, -9)]), col, 1.2, true)
			draw_polyline(PackedVector2Array([pos + Vector2(-7, -4), pos + Vector2(-9, 2), pos + Vector2(-4, 0), pos + Vector2(-7, -4)]), col, 1.2, true)
			draw_polyline(PackedVector2Array([pos + Vector2(7, -4), pos + Vector2(4, 0), pos + Vector2(9, 2), pos + Vector2(7, -4)]), col, 1.2, true)
		"rapid":
			# Twin interlocking chevrons
			draw_polyline(PackedVector2Array([pos + Vector2(-6, -3), pos + Vector2(0, -8), pos + Vector2(6, -3)]), col, 1.5, true)
			draw_polyline(PackedVector2Array([pos + Vector2(-6, 3), pos + Vector2(0, -2), pos + Vector2(6, 3)]), col, 1.5, true)
		"emp":
			# Concentric diamond crosshair
			draw_polyline(PackedVector2Array([pos + Vector2(0, -8), pos + Vector2(8, 0), pos + Vector2(0, 8), pos + Vector2(-8, 0), pos + Vector2(0, -8)]), col, 1.2, true)
			draw_line(pos + Vector2(-10, 0), pos + Vector2(10, 0), col, 1.2)
			draw_line(pos + Vector2(0, -10), pos + Vector2(0, 10), col, 1.2)
		"shield":
			# Hexagonal capsule
			var pts = PackedVector2Array()
			for i in range(7):
				var a = i * (PI / 3.0)
				pts.append(pos + Vector2(cos(a), sin(a)) * 8.5)
			draw_polyline(pts, col, 1.4, true)
			draw_circle(pos, 2.5, Color.WHITE)

# ==============================================================================
# NAVIGATION PIPS & BROWSER HELPER
# ==============================================================================
func _draw_navigation_pips(center: Vector2, font: Font):
	var pips_y = size.y - 18.0
	var pip_spacing = 18.0
	var start_x = center.x - (pip_spacing * 2) / 2.0
	
	for i in range(3):
		var p_pos = Vector2(start_x + i * pip_spacing, pips_y)
		if i == current_card:
			draw_circle(p_pos, 4.0, COLOR_GREEN)
			draw_circle(p_pos, 6.0, Color(COLOR_GREEN.r, COLOR_GREEN.g, COLOR_GREEN.b, 0.3))
		else:
			draw_circle(p_pos, 2.5, Color(COLOR_GREEN.r, COLOR_GREEN.g, COLOR_GREEN.b, 0.35))
			
	if font != null:
		var hint_text = "[◄ / ►] BROWSE INTEL"
		var h_sz = font.get_string_size(hint_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 10)
		draw_string(font, Vector2(center.x + 50.0, pips_y + 4.0), hint_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(COLOR_CYAN.r, COLOR_CYAN.g, COLOR_CYAN.b, 0.6))

