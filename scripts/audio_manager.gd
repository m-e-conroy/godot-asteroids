extends Node

const SAMPLE_RATE: int = 22050

var sfx_pool: Array[AudioStreamPlayer] = []
const POOL_SIZE: int = 8

var beat_player: AudioStreamPlayer = null
var beat_low_stream: AudioStreamWAV = null
var beat_high_stream: AudioStreamWAV = null
var powerup_stream: AudioStreamWAV = null
var bonus_life_stream: AudioStreamWAV = null
var emp_stream: AudioStreamWAV = null
var wave_clear_stream: AudioStreamWAV = null
var game_over_stream: AudioStreamWAV = null

var heartbeat_active: bool = false
var heartbeat_timer: float = 0.0
var heartbeat_interval: float = 1.0
var heartbeat_toggle: bool = false

var master_volume: float = 0.85

func _ready():
	add_to_group("audio_manager")
	process_mode = Node.PROCESS_MODE_PAUSABLE
	
	for i in range(POOL_SIZE):
		var p = AudioStreamPlayer.new()
		p.bus = &"Master"
		add_child(p)
		sfx_pool.append(p)
		
	beat_player = AudioStreamPlayer.new()
	beat_player.bus = &"Master"
	beat_player.volume_db = -6.0
	add_child(beat_player)
	
	_synthesize_all_sounds()

func _process(delta: float):
	if not heartbeat_active:
		return
		
	heartbeat_timer -= delta
	if heartbeat_timer <= 0.0:
		heartbeat_timer = heartbeat_interval
		beat_player.stream = beat_high_stream if heartbeat_toggle else beat_low_stream
		beat_player.play()
		heartbeat_toggle = !heartbeat_toggle

func set_heartbeat(active: bool, remaining_targets: int = 6):
	heartbeat_active = active
	if active:
		# Scale tempo from 1.10s (many targets) down to 0.24s (1 target left)
		var t: float = clamp(float(remaining_targets - 1) / 9.0, 0.0, 1.0)
		heartbeat_interval = lerpf(0.24, 1.10, t)

func set_master_volume(val: float):
	master_volume = clamp(val, 0.0, 1.0)
	var bus_idx = AudioServer.get_bus_index("Master")
	if bus_idx >= 0:
		AudioServer.set_bus_mute(bus_idx, master_volume <= 0.01)
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(max(master_volume, 0.0001)))

func get_master_volume() -> float:
	return master_volume

# ==============================================================================
# STATIC HELPERS
# ==============================================================================
static func play_powerup(tree: SceneTree):
	_call_play(tree, "_play_powerup")

static func play_bonus_life(tree: SceneTree):
	_call_play(tree, "_play_bonus_life")

static func play_emp(tree: SceneTree):
	_call_play(tree, "_play_emp")

static func play_wave_clear(tree: SceneTree):
	_call_play(tree, "_play_wave_clear")

static func play_game_over(tree: SceneTree):
	_call_play(tree, "_play_game_over")

static func _call_play(tree: SceneTree, method_name: String):
	if tree == null:
		return
	var am = tree.get_first_node_in_group("audio_manager")
	if am != null and am.has_method(method_name):
		am.call(method_name)

func _play_powerup():
	_play_stream(powerup_stream, -4.0)

func _play_bonus_life():
	_play_stream(bonus_life_stream, -2.0)

func _play_emp():
	_play_stream(emp_stream, -1.0)

func _play_wave_clear():
	_play_stream(wave_clear_stream, -4.0)

func _play_game_over():
	_play_stream(game_over_stream, -2.0)

func _play_stream(stream: AudioStream, vol_db: float = 0.0):
	if stream == null:
		return
	for p in sfx_pool:
		if not p.playing:
			p.stream = stream
			p.volume_db = vol_db
			p.play()
			return
	# Fallback if pool saturated
	sfx_pool[0].stream = stream
	sfx_pool[0].volume_db = vol_db
	sfx_pool[0].play()

# ==============================================================================
# PROCEDURAL RETRO SYNTHESIS
# ==============================================================================
func _synthesize_all_sounds():
	beat_low_stream = _make_tone_sweep(78.0, 58.0, 0.09, 0.55, "triangle")
	beat_high_stream = _make_tone_sweep(92.0, 68.0, 0.09, 0.55, "triangle")
	powerup_stream = _make_arpeggio([523.25, 659.25, 783.99, 1046.50], 0.065, 0.40, "square")
	bonus_life_stream = _make_arpeggio([659.25, 783.99, 1046.50, 783.99, 1318.51], 0.09, 0.45, "square")
	wave_clear_stream = _make_arpeggio([440.0, 554.37, 659.25, 880.0], 0.075, 0.38, "triangle")
	game_over_stream = _make_arpeggio([440.0, 392.0, 349.23, 293.66], 0.16, 0.45, "saw")
	emp_stream = _make_emp_boom(0.55)

func _make_tone_sweep(f_start: float, f_end: float, duration: float, amp: float, wave: String) -> AudioStreamWAV:
	var n: int = int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase: float = 0.0
	for i in range(n):
		var t: float = float(i) / float(n)
		var freq: float = lerpf(f_start, f_end, t)
		var env: float = (1.0 - t) * (1.0 - t)
		phase += (TAU * freq) / float(SAMPLE_RATE)
		var sample: float = _osc(phase, wave) * env * amp
		data.encode_s16(i * 2, int(clamp(sample, -1.0, 1.0) * 32767.0))
	return _build_wav(data)

func _make_arpeggio(freqs: Array, note_dur: float, amp: float, wave: String) -> AudioStreamWAV:
	var note_samples: int = int(SAMPLE_RATE * note_dur)
	var total_samples: int = note_samples * freqs.size()
	var data := PackedByteArray()
	data.resize(total_samples * 2)
	var phase: float = 0.0
	for n_idx in range(freqs.size()):
		var freq: float = freqs[n_idx]
		for i in range(note_samples):
			var t: float = float(i) / float(note_samples)
			var env: float = min(t * 10.0, 1.0) * (1.0 - t * 0.7)
			phase += (TAU * freq) / float(SAMPLE_RATE)
			var sample: float = _osc(phase, wave) * env * amp
			var idx: int = (n_idx * note_samples + i) * 2
			data.encode_s16(idx, int(clamp(sample, -1.0, 1.0) * 32767.0))
	return _build_wav(data)

func _make_emp_boom(duration: float) -> AudioStreamWAV:
	var n: int = int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase: float = 0.0
	for i in range(n):
		var t: float = float(i) / float(n)
		var freq: float = lerpf(210.0, 34.0, sqrt(t))
		var env: float = (1.0 - t) * (1.0 - t)
		phase += (TAU * freq) / float(SAMPLE_RATE)
		var bass: float = sin(phase) * 0.75
		var noise: float = randf_range(-1.0, 1.0) * 0.25 * (1.0 - t)
		var sample: float = (bass + noise) * env * 0.7
		data.encode_s16(i * 2, int(clamp(sample, -1.0, 1.0) * 32767.0))
	return _build_wav(data)

func _osc(phase: float, wave: String) -> float:
	var p: float = fposmod(phase, TAU) / TAU
	match wave:
		"square":
			return 0.7 if p < 0.5 else -0.7
		"triangle":
			return 1.0 - 4.0 * abs(p - 0.5)
		"saw":
			return 2.0 * p - 1.0
		_:
			return sin(phase)

func _build_wav(data: PackedByteArray) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream

