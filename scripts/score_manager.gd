extends Node

signal score_changed(new_score: int, is_high_score: bool)
signal high_score_changed(new_high_score: int)
signal lives_changed(new_lives: int)
signal wave_changed(new_wave: int)
signal bonus_life_awarded()
signal game_over(final_score: int, wave_reached: int, is_new_high: bool)

const SAVE_PATH: String = "user://highscore.save"
const BONUS_LIFE_STEP: int = 10000

var score: int = 0
var high_score: int = 0
var lives: int = 3
var wave: int = 1
var next_bonus_life_score: int = BONUS_LIFE_STEP
var is_game_over: bool = false
var is_new_high_score: bool = false

func _ready():
	add_to_group("score_manager")
	load_high_score()

static func award_points(tree: SceneTree, pts: int):
	if tree == null:
		return
	var sm = tree.get_first_node_in_group("score_manager")
	if sm != null:
		sm.add_score(pts)

func reset_game():
	score = 0
	lives = 3
	wave = 1
	next_bonus_life_score = BONUS_LIFE_STEP
	is_game_over = false
	is_new_high_score = false
	score_changed.emit(score, false)
	lives_changed.emit(lives)
	wave_changed.emit(wave)

func add_score(points: int):
	if is_game_over:
		return
		
	score += points
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

func lose_life() -> bool:
	if is_game_over:
		return false
		
	lives -= 1
	lives_changed.emit(lives)
	
	if lives <= 0:
		is_game_over = true
		game_over.emit(score, wave, is_new_high_score)
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
