extends CanvasLayer

signal launch_requested

@onready var background_dim = $BackgroundDim
@onready var top_bar = $TopBar
@onready var main_container = $VBoxContainer
@onready var vector_logo = $VBoxContainer/HeroSection/VectorLogo
@onready var attract_carousel = $VBoxContainer/CarouselSection/AttractCarousel
@onready var launch_prompt = $VBoxContainer/FooterSection/LaunchPrompt
@onready var high_score_display = $TopBar/HBox/HighScoreBox/HighScoreDisplay

var pulse_time: float = 0.0
var is_launching: bool = false

func _ready():
	_reset_visuals()
	
func _reset_visuals():
	is_launching = false
	pulse_time = 0.0
	visible = true
	if background_dim != null:
		background_dim.modulate.a = 1.0
	if top_bar != null:
		top_bar.modulate.a = 1.0
	if main_container != null:
		main_container.modulate.a = 1.0
		main_container.scale = Vector2.ONE
	
func set_high_score(val: int):
	if high_score_display != null and high_score_display.has_method("set_number"):
		high_score_display.set_number(val, true)

func _process(delta: float):
	if is_launching:
		return
		
	pulse_time += delta * 3.5
	if launch_prompt != null:
		launch_prompt.modulate.a = 0.5 + sin(pulse_time) * 0.45

func _input(event: InputEvent):
	if !visible or is_launching:
		return
		
	if event is InputEventKey and event.pressed and not event.is_echo():
		# Launch Triggers
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_R or event.keycode == KEY_SPACE:
			launch_game()
			get_viewport().set_input_as_handled()
		# Carousel Navigation
		elif event.keycode == KEY_RIGHT or event.keycode == KEY_D or event.keycode == KEY_TAB:
			if attract_carousel != null and attract_carousel.has_method("next_card"):
				attract_carousel.next_card()
				get_viewport().set_input_as_handled()
		elif event.keycode == KEY_LEFT or event.keycode == KEY_A:
			if attract_carousel != null and attract_carousel.has_method("prev_card"):
				attract_carousel.prev_card()
				get_viewport().set_input_as_handled()

func launch_game():
	if is_launching:
		return
	is_launching = true
	
	# Radial Hyperspace Warp Transition (0.35s)
	if main_container != null:
		main_container.pivot_offset = main_container.size / 2.0
		
	var tween = create_tween().set_parallel(true)
	if main_container != null:
		tween.tween_property(main_container, "scale", Vector2(1.15, 1.15), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(main_container, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if top_bar != null:
		tween.tween_property(top_bar, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if background_dim != null:
		tween.tween_property(background_dim, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		
	tween.chain().tween_callback(func():
		visible = false
		launch_requested.emit()
	)

func reset_to_welcome(high_score_val: int = 0):
	_reset_visuals()
	set_high_score(high_score_val)

