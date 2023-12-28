extends Node2D

@onready var player = $player
#@onready var rock = $rock

var bullet = preload("res://characters/bullet.tscn")
var asteroidScn = preload("res://characters/asteroid.tscn")

var rnd = RandomNumberGenerator.new()

func fireProjectile(pos, rot):
	var b = bullet.instantiate()
	b.position = pos
	b.rotation = rot
	b.velocity -= b.transform.y * 275
	add_child(b)
	
func asteroidDestroyed(pos, size):
	match size:
		'large':
			pass
		'medium':
			pass
		'small':
			pass
	
func generateAsteroids():
	var sizes = ['large','medium','small']
	var n = rnd.randi_range(3, 10)
	for i in n:
		var a = asteroidScn.instantiate()
		a.init(sizes[rnd.randi_range(0,2)])
		add_child(a)
		a.connect("destroyed", asteroidDestroyed)

# Called when the node enters the scene tree for the first time.
func _ready():
	player.connect("fired_projectile", fireProjectile)
	generateAsteroids()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
