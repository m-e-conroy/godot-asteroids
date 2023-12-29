extends CollisionShape2D

@onready var SHIELD_RADIUS = $"../../Sprite2D".SHIELD_RADIUS

func _ready():
	shape.radius = SHIELD_RADIUS
