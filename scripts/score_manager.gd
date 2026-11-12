extends Node

signal score_changed(new_score: int, is_high_score: bool)
signal high_score_changed(new_high_score: int)
signal lives_changed(new_lives: int)
signal wave_changed(new_wave: int)
signal bonus_life_awarded()
signal combo_changed(new_combo: int, time_ratio: float)
signal game_over(final_score: int, wave_reached: int, is_new_high: bool)

const SAVE_PATH: String = "user://highscore.save"
const BONUS_LIFE_STEP: int = 10000
const COMBO_WINDOW: float = 3.5
const MAX_COMBO: int = 8

var score: int = 0
var high_score: int = 0
var lives: int = 3
var wave: int = 1
var combo: int = 1
var combo_timer: float = 0.0
var next_bonus_life_score: int = BONUS_LIFE_STEP
var is_game_over: bool = false
var is_new_high_score: bool = false

func _ready():
	add_to_group("score_manager")
	load_high_score()

func _process(delta: float):
	if is_game_over:
		return
	if combo > 1 or combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo = 1
			combo_timer = 0.0
			combo_changed.emit(1, 0.0)
		else:
			combo_changed.emit(combo, combo_timer / COMBO_WINDOW)

static func award_points(tree: SceneTree, pts: int, world_pos: Vector2 = Vector2.ZERO):
	if tree == null:
		return
	var sm = tree.get_first_node_in_group("score_manager")
	if sm != null:
		sm.add_score(pts, world_pos)

func reset_game():
	score = 0
	lives = 3
	wave = 1
	combo = 1
	combo_timer = 0.0
	next_bonus_life_score = BONUS_LIFE_STEP
	is_game_over = false
	is_new_high_score = false
	score_changed.emit(score, false)
	lives_changed.emit(lives)
	wave_changed.emit(wave)
	combo_changed.emit(1, 0.0)

func add_score(points: int, world_pos: Vector2 = Vector2.ZERO):
	if is_game_over:
		return
		
	var active_combo: int = combo
	var total_pts: int = points * active_combo
	score += total_pts
	
	# Advance combo for next kill
	combo = min(combo + 1, MAX_COMBO)
	combo_timer = COMBO_WINDOW
	combo_changed.emit(combo, 1.0)
	
	if world_pos != Vector2.ZERO:
		var fs = load("res://effects/floating_score.gd")
		if fs != null:
			fs.spawn(get_tree(), world_pos, total_pts, active_combo)
	
	if score > high_score:
		high_score = score
		is_new_high_score = true
		high_score_changed.emit(high_score)
		save_high_score()
		
	score_changed.emit(score, is_new_high_score)
	
	# Check bonus life threshold
	if score >= next_bonus_life_score:
		next_bonus_life_score += BONUS_LIFE_STEP
		gain_life()

func gain_life():
	if lives < 6: # Sane cap on lives
		lives += 1
		lives_changed.emit(lives)
		bonus_life_awarded.emit()
		var am = load("res://scripts/audio_manager.gd")
		if am != null:
			am.play_bonus_life(get_tree())

func lose_life() -> bool:
	if is_game_over:
		return false
		
	combo = 1
	combo_timer = 0.0
	combo_changed.emit(1, 0.0)
	lives -= 1
	lives_changed.emit(lives)
	
	if lives <= 0:
		is_game_over = true
		game_over.emit(score, wave, is_new_high_score)
		var am = load("res://scripts/audio_manager.gd")
		if am != null:
			am.play_game_over(get_tree())
		return false
	return true

func set_wave(new_wave: int):
	wave = new_wave
	wave_changed.emit(wave)

func load_high_score():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file != null:
			var val = file.get_as_text().strip_edges()
			if val.is_valid_int():
				high_score = val.to_int()
			file.close()
	high_score_changed.emit(high_score)

func save_high_score():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(str(high_score))
		file.close()
