extends Area2D

@onready var PARENT := get_parent()

@export_group('Shield Collision Parameters')
@export var COLLISION_TIME_BEFORE_SHIELDS_DAMAGED := 0.25

var collisionAccumulatedTime := 0.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if has_overlapping_bodies() && PARENT.SHIELD && (PARENT.SHIELD_STRENGTH > 0.0):
		collisionAccumulatedTime += delta
		if collisionAccumulatedTime > COLLISION_TIME_BEFORE_SHIELDS_DAMAGED:
			collisionAccumulatedTime = 0.0
			PARENT.SHIELD_STRENGTH -= 1.0
			if PARENT.SHIELD_STRENGTH < 0.0:
				PARENT.SHIELD_STRENGTH = 0.0
