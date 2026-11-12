extends Sprite2D

@onready var PARENT := get_parent()

# drawing shapes
const SHIP_SHAPE: Array = [Vector2(0,-15), Vector2(7,10), Vector2(0,5), Vector2(-7,10), Vector2(0,-15)]
const RT_THRUSTER_SHAPE: Array = [Vector2(5,-10), Vector2(15,-12), Vector2(4,-14), Vector2(5,-10)]
const LT_THRUSTER_SHAPE: Array = [Vector2(-5,-10), Vector2(-15,-12), Vector2(-4,-14), Vector2(-5,-10)]
const THRUSTER_SHAPE: Array = [Vector2(3,11), Vector2(0,30), Vector2(-3,11), Vector2(3,11)]

@export_group('Ship Graphic Parameters')
@export var SHIELD_RADIUS := 40.0
@export var FORCE_FIELD_COLOR: Color = Color(0.25, 0.75, 1.0, 0.95)
@export var FORCE_FIELD_COUNTDOWN_COLOR: Color = Color(0.7, 0.95, 1.0, 0.95)
@export var FORCE_FIELD_RECHARGE_COLOR: Color = Color(0.25, 0.7, 1.0, 0.28)
@export var SHIP_COLOR: Color = Color.LAWN_GREEN

var thrusterColorGradient: PackedColorArray = PackedColorArray([Color(0.25, 0.85, 1.0, 0.9), Color(1.0, 0.75, 0.2, 0.2), Color(0.25, 0.85, 1.0, 0.9), Color(0.25, 0.85, 1.0, 0.9)])
var pulse_time: float = 0.0

func _process(delta):
	pulse_time += delta * 4.0
	queue_redraw() # calls _draw again, needed for thrusters and gauges

func _draw():
	var flicker: float = 0.85 + 0.3 * abs(sin(pulse_time * 9.5))
	
	# 1. Draw thrusters when parent variable is true for that thruster
	if PARENT.TURN_LEFT:
		draw_polyline(PackedVector2Array(RT_THRUSTER_SHAPE), Color(0.25, 0.85, 1.0, 0.8), 1.8)
	if PARENT.TURN_RIGHT:
		draw_polyline(PackedVector2Array(LT_THRUSTER_SHAPE), Color(0.25, 0.85, 1.0, 0.8), 1.8)
	if PARENT.THRUST:
		var flame_tip = Vector2(0, 26.0 * flicker + 6.0)
		var outer_flame = PackedVector2Array([Vector2(4, 10), flame_tip, Vector2(-4, 10), Vector2(4, 10)])
		var inner_flame = PackedVector2Array([Vector2(2, 10), Vector2(0, 18.0 * flicker + 4.0), Vector2(-2, 10), Vector2(2, 10)])
		draw_polyline(outer_flame, Color(1.0, 0.65, 0.15, 0.85), 2.5)
		draw_polyline(inner_flame, Color(0.85, 1.0, 1.0, 0.95), 1.6)

	# 2. Draw the ship (with subtle phosphor halo + sharp core)
	draw_polyline(PackedVector2Array(SHIP_SHAPE), Color(SHIP_COLOR.r, SHIP_COLOR.g, SHIP_COLOR.b, 0.35), 4.5)
	draw_polyline(PackedVector2Array(SHIP_SHAPE), SHIP_COLOR, 2.0)

	# 2b. Draw weapon mode visual enhancements
	if "weapon_mode" in PARENT:
		match PARENT.weapon_mode:
			PARENT.WeaponMode.TRIPLE_SHOT:
				var gold: Color = Color(1.0, 0.8, 0.15)
				# Left & right angled stabilizer wings
				draw_line(Vector2(-7, 10), Vector2(-12, 14), gold, 2.0)
				draw_line(Vector2(7, 10), Vector2(12, 14), gold, 2.0)
				# Triple weapon nozzle indicator pips
				draw_circle(Vector2(0, -17), 2.0, gold)
				draw_circle(Vector2(-5, -6), 1.5, gold)
				draw_circle(Vector2(5, -6), 1.5, gold)
			PARENT.WeaponMode.RAPID_FIRE:
				var magenta: Color = Color(1.0, 0.25, 0.8)
				# Dual animated lightning chevrons on hull
				var shift: float = sin(pulse_time * 2.0) * 1.5
				draw_polyline(PackedVector2Array([Vector2(-4, 0 + shift), Vector2(0, -6 + shift), Vector2(4, 0 + shift)]), magenta, 2.0)
				draw_polyline(PackedVector2Array([Vector2(-3, 6 + shift), Vector2(0, 1 + shift), Vector2(3, 6 + shift)]), magenta, 2.0)

	# 3. Force Field & Gauge Rendering
	if "force_field_state" in PARENT:
		match PARENT.force_field_state:
			PARENT.ForceFieldState.ACTIVE:
				# A. Soft inner radial glow fill
				draw_circle(Vector2.ZERO, SHIELD_RADIUS, Color(0.1, 0.5, 1.0, 0.12))
				
				# B. Subtle pulsing secondary outer aura
				var pulse_alpha = 0.25 + sin(pulse_time) * 0.1
				draw_arc(Vector2.ZERO, SHIELD_RADIUS + 2.5, 0.0, 2.0 * PI, 48, Color(0.15, 0.65, 1.0, pulse_alpha), 1.5)
				
				# C. Crisp outer perimeter ring
				draw_arc(Vector2.ZERO, SHIELD_RADIUS, 0.0, 2.0 * PI, 48, FORCE_FIELD_COLOR, 2.5)
				
				# D. Thicker countdown clock arc (sweeps down clockwise from 12 o'clock / -PI/2)
				var countdown_ratio: float = clamp(PARENT.force_field_active_timer / PARENT.FORCE_FIELD_ACTIVE_TIME, 0.0, 1.0)
				if countdown_ratio > 0.001:
					var arc_angle: float = countdown_ratio * 2.0 * PI
					draw_arc(Vector2.ZERO, SHIELD_RADIUS - 6.0, -PI / 2.0, -PI / 2.0 + arc_angle, 48, FORCE_FIELD_COUNTDOWN_COLOR, 4.0)
					
			PARENT.ForceFieldState.RECHARGING:
				# Faint recharge ring sweeping up clockwise from 12 o'clock, disappearing when ready
				var recharge_ratio: float = clamp(PARENT.force_field_recharge_timer / PARENT.FORCE_FIELD_RECHARGE_TIME, 0.0, 1.0)
				if recharge_ratio > 0.001 and recharge_ratio < 0.999:
					var arc_angle: float = recharge_ratio * 2.0 * PI
					draw_arc(Vector2.ZERO, SHIELD_RADIUS - 6.0, -PI / 2.0, -PI / 2.0 + arc_angle, 48, FORCE_FIELD_RECHARGE_COLOR, 2.0)
