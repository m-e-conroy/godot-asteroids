extends CanvasLayer

signal resume_requested
signal restart_requested
signal briefing_requested
signal crt_toggled(enabled: bool)

@onready var volume_slider = $CenterContainer/Panel/Margin/VBox/VolumeRow/VolumeSlider
@onready var volume_val_label = $CenterContainer/Panel/Margin/VBox/VolumeRow/VolumeVal
@onready var crt_button = $CenterContainer/Panel/Margin/VBox/CrtRow/CrtToggleBtn
@onready var resume_button = $CenterContainer/Panel/Margin/VBox/ResumeBtn

var crt_enabled: bool = true

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	# Sync initial volume if audio_manager exists
	var am = get_tree().get_first_node_in_group("audio_manager")
	if am != null and am.has_method("get_master_volume"):
		var v = am.get_master_volume()
		volume_slider.value = v * 100.0
		volume_val_label.text = "%d%%" % int(round(v * 100.0))

func open_pause():
	visible = true
	get_tree().paused = true
	if resume_button != null:
		resume_button.grab_focus()

func close_pause():
	visible = false
	get_tree().paused = false

func _input(event: InputEvent):
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
			close_pause()
			resume_requested.emit()
			get_viewport().set_input_as_handled()

func _on_resume_btn_pressed():
	close_pause()
	resume_requested.emit()

func _on_restart_btn_pressed():
	close_pause()
	restart_requested.emit()

func _on_briefing_btn_pressed():
	close_pause()
	briefing_requested.emit()

func _on_volume_slider_value_changed(value: float):
	volume_val_label.text = "%d%%" % int(round(value))
	var am = get_tree().get_first_node_in_group("audio_manager")
	if am != null and am.has_method("set_master_volume"):
		am.set_master_volume(value / 100.0)

func _on_crt_toggle_btn_pressed():
	crt_enabled = !crt_enabled
	crt_button.text = "ON" if crt_enabled else "OFF"
	crt_toggled.emit(crt_enabled)
