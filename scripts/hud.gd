extends CanvasLayer

@onready var score_display = $MarginContainer/TopBar/ScoreBox/ScoreDisplay
@onready var high_score_display = $MarginContainer/TopBar/HighScoreBox/HighScoreDisplay
@onready var wave_display = $MarginContainer/TopBar/WaveBox/WaveDisplay
@onready var lives_control = $MarginContainer/TopBar/LivesBox/LivesControl

@onready var shield_panel = $BottomBar/ShieldPanel
@onready var shield_label = $BottomBar/ShieldPanel/HBox/ShieldLabel
@onready var shield_progress = $BottomBar/ShieldPanel/HBox/ShieldProgress

@onready var weapon_panel = $BottomBar/WeaponPanel
@onready var weapon_label = $BottomBar/WeaponPanel/HBox/WeaponLabel
@onready var weapon_progress = $BottomBar/WeaponPanel/HBox/WeaponProgress

@onready var combo_panel = $BottomBar/ComboPanel
@onready var combo_label = $BottomBar/ComboPanel/HBox/ComboLabel
@onready var combo_progress = $BottomBar/ComboPanel/HBox/ComboProgress

@onready var boss_panel = $BossPanel
@onready var boss_name_label = $BossPanel/VBox/BossNameLabel
@onready var boss_hp_progress = $BossPanel/VBox/BossHpProgress

@onready var game_over_overlay = $GameOverOverlay
@onready var go_final_score = $GameOverOverlay/VBox/ScoreBox/FinalScoreDisplay
@onready var go_high_score = $GameOverOverlay/VBox/HighScoreBox/HighDisplay
@onready var go_new_high_label = $GameOverOverlay/VBox/NewHighLabel
@onready var go_timeout_label = $GameOverOverlay/VBox/TimeoutLabel
@onready var wave_announce_label = $WaveAnnounceLabel
@onready var mutator_announce_label = $MutatorAnnounceLabel
@onready var mutator_badge_label = $MutatorBadgeLabel
@onready var salvage_panel = $BottomBar/SalvagePanel
@onready var salvage_label = $BottomBar/SalvagePanel/SalvageLabel
@onready var salvage_toast_label = $SalvageToastLabel
@onready var warp_panel = $BottomBar/WarpPanel
@onready var warp_label = $BottomBar/WarpPanel/WarpLabel
@onready var initial_entry_box = $GameOverOverlay/VBox/InitialEntryBox
@onready var initial_slots = [
	$GameOverOverlay/VBox/InitialEntryBox/SlotRow/Slot0,
	$GameOverOverlay/VBox/InitialEntryBox/SlotRow/Slot1,
	$GameOverOverlay/VBox/InitialEntryBox/SlotRow/Slot2
]

const INITIAL_CHARS: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-"
var score_manager_ref: Node = null
var entering_initials: bool = false
var initial_indices: Array[int] = [0, 0, 0]
var active_slot: int = 0
var pending_final_score: int = 0
var pending_wave_reached: int = 1

var current_lives: int = 3
var current_high_score: int = 0
var player_node: Node2D = null
var pulse_time: float = 0.0
var show_restart_prompt: bool = false

const COLOR_GREEN: Color = Color(0.16, 0.94, 0.0)
const COLOR_CYAN: Color = Color(0.25, 0.75, 1.0)
const COLOR_GOLD: Color = Color(1.0, 0.8, 0.15)
const COLOR_MAGENTA: Color = Color(1.0, 0.25, 0.8)

func _ready():
	game_over_overlay.visible = false
	weapon_panel.visible = false
	combo_panel.visible = false
	boss_panel.visible = false
	wave_announce_label.visible = false
	mutator_announce_label.visible = false
	mutator_badge_label.visible = false
	salvage_panel.visible = false
	salvage_toast_label.visible = false
	$GameOverOverlay/VBox/RestartPrompt.visible = false

func connect_score_manager(score_mgr: Node):
	if score_mgr == null:
		return
	score_manager_ref = score_mgr
	score_mgr.score_changed.connect(_on_score_changed)
	score_mgr.high_score_changed.connect(_on_high_score_changed)
	score_mgr.lives_changed.connect(_on_lives_changed)
	score_mgr.wave_changed.connect(_on_wave_changed)
	if score_mgr.has_signal("combo_changed"):
		score_mgr.combo_changed.connect(_on_combo_changed)
	score_mgr.game_over.connect(_on_game_over)
	
	# Initial populate
	_on_score_changed(score_mgr.score, false)
	_on_high_score_changed(score_mgr.high_score)
	_on_lives_changed(score_mgr.lives)
	_on_wave_changed(score_mgr.wave)

func set_player(player: Node2D):
	player_node = player
	if player_node != null and player_node.has_signal("salvage_updated"):
		if not player_node.salvage_updated.is_connected(_on_salvage_updated):
			player_node.salvage_updated.connect(_on_salvage_updated)

func _process(delta: float):
	pulse_time += delta * 4.0
	
	# Update Shield HUD Widget
	_update_shield_widget()
	
	# Update Warp HUD Widget
	_update_warp_widget()
	
	# Update Weapon Buff Widget
	_update_weapon_widget()
	
	# Pulse Game Over restart label if active
	if game_over_overlay.visible and show_restart_prompt:
		var prompt = $GameOverOverlay/VBox/RestartPrompt
		prompt.modulate.a = 0.5 + sin(pulse_time * 1.5) * 0.4

func _update_warp_widget():
	if warp_panel == null or warp_label == null:
		return
	if player_node == null or !is_instance_valid(player_node) or player_node.is_dead:
		warp_panel.visible = false
		return
	warp_panel.visible = true
	if "hyperspace_cooldown_timer" in player_node:
		var cd: float = player_node.hyperspace_cooldown_timer
		if cd <= 0.0:
			warp_label.text = "WARP: READY"
			warp_label.modulate = COLOR_CYAN
		else:
			warp_label.text = "WARP: %.1fs" % cd
			warp_label.modulate = Color(COLOR_CYAN.r, COLOR_CYAN.g, COLOR_CYAN.b, 0.5)

func _update_shield_widget():
	if player_node == null or !is_instance_valid(player_node) or player_node.is_dead:
		shield_panel.visible = false
		return
		
	shield_panel.visible = true
	if "force_field_state" in player_node:
		match player_node.force_field_state:
			player_node.ForceFieldState.READY:
				shield_label.text = "SHIELD: READY"
				shield_label.modulate = COLOR_CYAN
				shield_progress.value = 100.0
				shield_progress.modulate = COLOR_CYAN
			player_node.ForceFieldState.ACTIVE:
				var t_left = max(0.0, player_node.force_field_active_timer)
				shield_label.text = "SHIELD: ACTIVE %.1fs" % t_left
				shield_label.modulate = Color.WHITE
				var ratio = t_left / player_node.FORCE_FIELD_ACTIVE_TIME
				shield_progress.value = ratio * 100.0
				shield_progress.modulate = COLOR_CYAN
			player_node.ForceFieldState.RECHARGING:
				var t_left = max(0.0, player_node.FORCE_FIELD_RECHARGE_TIME - player_node.force_field_recharge_timer)
				shield_label.text = "SHIELD: CHG %.1fs" % t_left
				shield_label.modulate = Color(COLOR_CYAN.r, COLOR_CYAN.g, COLOR_CYAN.b, 0.6)
				var ratio = player_node.force_field_recharge_timer / player_node.FORCE_FIELD_RECHARGE_TIME
				shield_progress.value = ratio * 100.0
				shield_progress.modulate = Color(COLOR_CYAN.r, COLOR_CYAN.g, COLOR_CYAN.b, 0.4)

func _update_weapon_widget():
	if player_node == null or !is_instance_valid(player_node) or player_node.is_dead:
		weapon_panel.visible = false
		return
		
	if "weapon_mode" in player_node and player_node.weapon_mode != player_node.WeaponMode.NORMAL:
		weapon_panel.visible = true
		var t_left = max(0.0, player_node.weapon_timer)
		var ratio = (t_left / player_node.WEAPON_BUFF_DURATION) * 100.0
		weapon_progress.value = ratio
		
		if player_node.weapon_mode == player_node.WeaponMode.TRIPLE_SHOT:
			weapon_label.text = "TRIPLE SHOT %.1fs" % t_left
			weapon_label.modulate = COLOR_GOLD
			weapon_progress.modulate = COLOR_GOLD
		elif player_node.weapon_mode == player_node.WeaponMode.RAPID_FIRE:
			weapon_label.text = "RAPID FIRE %.1fs" % t_left
			weapon_label.modulate = COLOR_MAGENTA
			weapon_progress.modulate = COLOR_MAGENTA
	else:
		weapon_panel.visible = false

func _on_score_changed(score: int, is_high: bool):
	score_display.set_number(score, true)
	if is_high:
		score_display.color_lit = COLOR_GOLD
	else:
		score_display.color_lit = COLOR_GREEN

func _on_high_score_changed(high_score: int):
	current_high_score = high_score
	high_score_display.set_number(high_score, true)

func _on_lives_changed(lives: int):
	current_lives = lives
	lives_control.queue_redraw()

func _on_wave_changed(wave: int):
	wave_display.set_number(wave, true)
	_announce_wave(wave)

func _announce_wave(wave: int):
	wave_announce_label.text = "WAVE %02d" % wave
	wave_announce_label.visible = true
	wave_announce_label.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property(wave_announce_label, "scale", Vector2(1.2, 1.2), 0.3).from(Vector2(0.8, 0.8))
	tween.tween_interval(1.2)
	tween.tween_property(wave_announce_label, "modulate:a", 0.0, 0.6)
	tween.tween_callback(func(): wave_announce_label.visible = false)

func is_entering_initials() -> bool:
	return game_over_overlay.visible and entering_initials

func _input(event: InputEvent):
	if not is_entering_initials():
		return
	if event is InputEventKey and event.pressed and not event.is_echo():
		var count: int = INITIAL_CHARS.length()
		if event.keycode == KEY_LEFT or event.keycode == KEY_A and event.shift_pressed:
			active_slot = (active_slot + 2) % 3
			_update_initial_slots()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_RIGHT:
			active_slot = (active_slot + 1) % 3
			_update_initial_slots()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_UP:
			initial_indices[active_slot] = (initial_indices[active_slot] + 1) % count
			_update_initial_slots()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_DOWN:
			initial_indices[active_slot] = (initial_indices[active_slot] + count - 1) % count
			_update_initial_slots()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_BACKSPACE:
			active_slot = max(0, active_slot - 1)
			_update_initial_slots()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_submit_initials()
			get_viewport().set_input_as_handled()
		elif event.unicode > 0:
			var ch: String = char(event.unicode).to_upper()
			var idx: int = INITIAL_CHARS.find(ch)
			if idx != -1:
				initial_indices[active_slot] = idx
				active_slot = min(2, active_slot + 1)
				_update_initial_slots()
				get_viewport().set_input_as_handled()

func _update_initial_slots():
	for i in range(3):
		var lbl = initial_slots[i]
		lbl.text = INITIAL_CHARS[initial_indices[i]]
		var col: Color = COLOR_GOLD if i == active_slot else COLOR_GREEN
		lbl.add_theme_color_override("font_color", col)

func _submit_initials():
	var initials := ""
	for i in range(3):
		initials += INITIAL_CHARS[initial_indices[i]]
	entering_initials = false
	if initial_entry_box != null:
		initial_entry_box.visible = false
	if score_manager_ref != null and score_manager_ref.has_method("submit_leaderboard_entry"):
		score_manager_ref.submit_leaderboard_entry(initials, pending_final_score, pending_wave_reached)
	var prompt = $GameOverOverlay/VBox/RestartPrompt
	prompt.visible = true
	prompt.modulate.a = 1.0
	show_restart_prompt = true
	if go_timeout_label != null:
		go_timeout_label.visible = true

func _on_game_over(final_score: int, wave_reached: int, is_new_high: bool):
	game_over_overlay.visible = true
	go_final_score.set_number(final_score, true)
	go_high_score.set_number(current_high_score, true)
	go_new_high_label.visible = is_new_high
	pending_final_score = final_score
	pending_wave_reached = wave_reached
	
	var prompt = $GameOverOverlay/VBox/RestartPrompt
	prompt.visible = false
	prompt.modulate.a = 0.0
	show_restart_prompt = false
	
	var qualifies: bool = score_manager_ref != null and score_manager_ref.has_method("qualifies_for_leaderboard") and score_manager_ref.qualifies_for_leaderboard(final_score)
	if qualifies and initial_entry_box != null:
		entering_initials = true
		active_slot = 0
		initial_entry_box.visible = true
		if go_timeout_label != null:
			go_timeout_label.visible = false
		_update_initial_slots()
	else:
		entering_initials = false
		if initial_entry_box != null:
			initial_entry_box.visible = false
		if go_timeout_label != null:
			go_timeout_label.visible = true
		get_tree().create_timer(1.0).timeout.connect(func():
			if game_over_overlay.visible and not entering_initials:
				prompt.visible = true
				show_restart_prompt = true
		)

func hide_game_over():
	game_over_overlay.visible = false
	entering_initials = false
	show_restart_prompt = false
	if initial_entry_box != null:
		initial_entry_box.visible = false
	var prompt = $GameOverOverlay/VBox/RestartPrompt
	prompt.visible = false

func set_game_over_countdown(seconds_left: float):
	if go_timeout_label != null:
		var secs: int = max(0, ceili(seconds_left))
		go_timeout_label.text = "RETURNING TO BRIEFING IN %ds" % secs

func _on_combo_changed(new_combo: int, time_ratio: float):
	if combo_panel == null:
		return
	if new_combo <= 1:
		combo_panel.visible = false
	else:
		combo_panel.visible = true
		combo_label.text = "COMBO x%d" % new_combo
		var col = COLOR_GOLD if new_combo < 5 else COLOR_MAGENTA
		combo_label.modulate = col
		combo_progress.modulate = col
		combo_progress.value = clamp(time_ratio * 100.0, 0.0, 100.0)

func update_boss_hp(hp: int, max_hp: int, b_name: String):
	if boss_panel == null:
		return
	boss_panel.visible = true
	boss_name_label.text = b_name
	boss_hp_progress.max_value = max_hp
	boss_hp_progress.value = hp

func hide_boss_bar():
	if boss_panel != null:
		boss_panel.visible = false

func announce_mutator(title: String, col: Color = COLOR_MAGENTA):
	if mutator_announce_label != null:
		mutator_announce_label.text = title
		mutator_announce_label.add_theme_color_override("font_color", col)
		mutator_announce_label.visible = true
		mutator_announce_label.modulate.a = 1.0
		var tween = create_tween()
		tween.tween_property(mutator_announce_label, "scale", Vector2(1.12, 1.12), 0.25).from(Vector2(0.85, 0.85))
		tween.tween_interval(1.6)
		tween.tween_property(mutator_announce_label, "modulate:a", 0.0, 0.6)
		tween.tween_callback(func(): mutator_announce_label.visible = false)
	if mutator_badge_label != null:
		mutator_badge_label.text = title
		mutator_badge_label.add_theme_color_override("font_color", Color(col.r, col.g, col.b, 0.85))
		mutator_badge_label.visible = true

func clear_mutator():
	if mutator_announce_label != null:
		mutator_announce_label.visible = false
	if mutator_badge_label != null:
		mutator_badge_label.visible = false

func _on_salvage_updated(stacks: Dictionary):
	if salvage_panel == null or salvage_label == null:
		return
	var parts: Array[String] = []
	var twin: int = stacks.get("twin_guns", 0)
	var bullets: int = stacks.get("more_bullets", 0)
	var shd_dur: int = stacks.get("shield_duration", 0)
	var shd_cd: int = stacks.get("shield_cooldown", 0)
	if twin > 0:
		parts.append("TWIN x%d" % twin)
	if bullets > 0:
		parts.append("CAP +%d" % (bullets * 2))
	if shd_dur > 0:
		parts.append("SHD +%ds" % (shd_dur * 2))
	if shd_cd > 0:
		parts.append("CHG -%.1fs" % (shd_cd * 2.5))
	if parts.is_empty():
		salvage_panel.visible = false
	else:
		salvage_label.text = "SALVAGE: " + "  |  ".join(parts)
		salvage_panel.visible = true

func announce_salvage(title: String, col: Color = Color(1.0, 0.72, 0.15)):
	if salvage_toast_label == null:
		return
	salvage_toast_label.text = title
	salvage_toast_label.add_theme_color_override("font_color", col)
	salvage_toast_label.visible = true
	salvage_toast_label.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property(salvage_toast_label, "scale", Vector2(1.1, 1.1), 0.2).from(Vector2(0.85, 0.85))
	tween.tween_interval(1.4)
	tween.tween_property(salvage_toast_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): salvage_toast_label.visible = false)
