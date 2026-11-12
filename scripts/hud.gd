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
	$GameOverOverlay/VBox/RestartPrompt.visible = false

func connect_score_manager(score_mgr: Node):
	if score_mgr == null:
		return
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

func _process(delta: float):
	pulse_time += delta * 4.0
	
	# Update Shield HUD Widget
	_update_shield_widget()
	
	# Update Weapon Buff Widget
	_update_weapon_widget()
	
	# Pulse Game Over restart label if active
	if game_over_overlay.visible and show_restart_prompt:
		var prompt = $GameOverOverlay/VBox/RestartPrompt
		prompt.modulate.a = 0.5 + sin(pulse_time * 1.5) * 0.4

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

func _on_game_over(final_score: int, wave_reached: int, is_new_high: bool):
	game_over_overlay.visible = true
	go_final_score.set_number(final_score, true)
	go_high_score.set_number(current_high_score, true)
	go_new_high_label.visible = is_new_high
	
	var prompt = $GameOverOverlay/VBox/RestartPrompt
	prompt.visible = false
	prompt.modulate.a = 0.0
	show_restart_prompt = false
	get_tree().create_timer(1.0).timeout.connect(func():
		if game_over_overlay.visible:
			prompt.visible = true
			show_restart_prompt = true
	)

func hide_game_over():
	game_over_overlay.visible = false
	show_restart_prompt = false
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
