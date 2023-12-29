extends Node2D

@onready var screen_size = get_viewport_rect().size

var bullet = preload("res://characters/bullet.tscn")
var asteroidScn = preload("res://Enemies/Asteroid/asteroid.tscn")
var rock_crash = preload("res://effects/rock_crash.tscn")

var rnd = RandomNumberGenerator.new()

var clones: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	$player.global_position = screen_size / 2
	$player.connect("bullet_impact", showBulletImpact)
	generateAsteroids()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
	
func randomPosNegOne():
	var one = rnd.randf_range(-1,1)
	if one < 0:
		return -1
	else:
		return 1
# end randomPosNegOne

func generateAsteroids():
	var sizes = ['lg','md','sm','xs']
	var n = rnd.randi_range(4,7)
	
	for i in n:
		var a = asteroidScn.instantiate()
		a.SIZE = sizes[rnd.randi_range(0,3)]
		a.position = Vector2(rnd.randi_range(0, screen_size.x), rnd.randi_range(0, screen_size.y))
		a.linear_velocity = Vector2(rnd.randi_range(4,16) * randomPosNegOne(), rnd.randi_range(4,16) * randomPosNegOne())
		a.angular_velocity = (randomPosNegOne() * rnd.randi_range(1,45)) * PI / 180
		add_child(a)
		a.connect("destroyed", asteroidDestroyed)
			
func asteroidDestroyed(pos, size):
	# explosion
	match size:
		'lg': # break into 4 small, 2 small 1 medium, or 2 medium asteroids
			match rnd.randi_range(0,2):
				0:
					for i in 4:
						var a = asteroidScn.instantiate()
						a.size = 'sm'
						a.position = pos
						a.linear_velocity = Vector2(rnd.randi_range(4,16) * randomPosNegOne(), rnd.randi_range(4,16) * randomPosNegOne())
						a.angular_velocity = (randomPosNegOne() * rnd.randi_range(1,45)) * PI / 180
						add_child(a)
						a.connect("destroyed", asteroidDestroyed)
				1:
					for i in 2:
						var a = asteroidScn.instantiate()
						a.size = 'sm'
						a.position = pos
						a.linear_velocity = Vector2(rnd.randi_range(4,16) * randomPosNegOne(), rnd.randi_range(4,16) * randomPosNegOne())
						a.angular_velocity = (randomPosNegOne() * rnd.randi_range(1,45)) * PI / 180
						add_child(a)
						a.connect("destroyed", asteroidDestroyed)
				2:
					for i in 2:
						var a = asteroidScn.instantiate()
						a.size = 'md'
						a.position = pos
						a.linear_velocity = Vector2(rnd.randi_range(4,16) * randomPosNegOne(), rnd.randi_range(4,16) * randomPosNegOne())
						a.angular_velocity = (randomPosNegOne() * rnd.randi_range(1,45)) * PI / 180
						add_child(a)
						a.connect("destroyed", asteroidDestroyed)
		'md': # break into 2 or 3 small ones
			var num := rnd.randi_range(2,3)
			for i in num:
				var a = asteroidScn.instantiate()
				
				a.size = 'sm'
				a.position = pos
				a.linear_velocity = Vector2(rnd.randi_range(4,16) * randomPosNegOne(), rnd.randi_range(4,16) * randomPosNegOne())
				a.angular_velocity = (randomPosNegOne() * rnd.randi_range(1,45)) * PI / 180
				add_child(a)
				a.connect("destroyed", asteroidDestroyed)
	showAsteroidExplosion(pos)	

func showBulletImpact(pos):
	var crash = rock_crash.instantiate()
	crash.global_position = pos
	crash.get_child(0).amount = 25
	crash.get_child(0).color = Color.WHITE
	add_child(crash)
	crash.get_child(0).emitting = true
# end showBulletImpact

func showAsteroidExplosion(pos):
	var crash = rock_crash.instantiate()
	crash.global_position = pos
	crash.get_child(0).amount = 50
	crash.get_child(0).lifetime = 2
	crash.get_child(0).speed_scale = 2
	crash.get_child(0).color = Color.WHITE
	add_child(crash)
	crash.get_child(0).emitting = true
	
# end showAsteroidExplosion

