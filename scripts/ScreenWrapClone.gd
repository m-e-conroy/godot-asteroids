extends Node2D

@onready var objSize = $"..".radius
@onready var sprite = $".."/Sprite2D
@onready var collisionShape = $".."/CollisionPolygon2D
@onready var screen_size = get_viewport_rect().size

var topClone: Sprite2D = null
var topCollide: CollisionPolygon2D = null
var botClone: Sprite2D = null
var botCollide: CollisionPolygon2D = null
var ltClone: Sprite2D = null
var ltCollide: CollisionPolygon2D = null
var rtClone: Sprite2D = null
var rtCollide: CollisionPolygon2D = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _process(_delta):
	if $"..".polyPts.size() > 0:
		# test to see if Y is off screen
		if sprite.global_position.y + objSize > screen_size.y:
			if topClone == null:
				print("CREATE TOP CLONE")
				topClone = sprite.duplicate()
				topCollide = collisionShape.duplicate()
				$"..".add_child(topClone)
				$"..".add_child(topCollide)
				topClone.global_position = Vector2(sprite.global_position.x, (-1 * (screen_size.y - sprite.global_position.y)))
				topCollide.global_position = topClone.global_position
			else:
				topClone.global_position = Vector2(sprite.global_position.x, (-1 * (screen_size.y - sprite.global_position.y)))
				topCollide.global_position = topClone.global_position
		elif topClone != null:
			topClone.queue_free()
			topClone = null
			topCollide.queue_free()
			topCollide = null
			
		if sprite.global_position.y - objSize < 0:
			if botClone == null:
				print("CREATE BOTTOM CLONE")
				botClone = sprite.duplicate()
				botCollide = collisionShape.duplicate()
				$"..".add_child(botClone)
				$"..".add_child(botCollide)
				botClone.global_position = Vector2(sprite.global_position.x, (sprite.global_position.y + screen_size.y))
				botCollide.global_position = botClone.global_position
			else:
				botClone.global_position = Vector2(sprite.global_position.x, (sprite.global_position.y + screen_size.y))
				botCollide.global_position = botClone.global_position
		elif botClone != null:
			botClone.queue_free()
			botClone = null
			botCollide.queue_free()
			botCollide = null
				
		if sprite.global_position.x + objSize > screen_size.x:
			if ltClone == null:
				print("CREATE LEFT CLONE")
				ltClone = sprite.duplicate()
				ltCollide = collisionShape.duplicate()
				$"..".add_child(ltClone)
				$"..".add_child(ltCollide)
				ltClone.global_position = Vector2((-1 * (screen_size.x - sprite.global_position.y)), sprite.global_position.y)
				ltCollide.global_position = ltClone.global_position
			else:
				ltClone.global_position = Vector2((-1 * (screen_size.x - sprite.global_position.y)), sprite.global_position.y)
				ltCollide.global_position = ltClone.global_position
		elif ltClone != null:
			ltClone.queue_free()
			ltClone = null
			ltCollide.queue_free()
			ltCollide = null
			
		if sprite.global_position.x - objSize < 0:
			if rtClone == null:
				print("CREATE RIGHT CLONE")
				rtClone = sprite.duplicate()
				rtCollide = collisionShape.duplicate()
				$"..".add_child(rtClone)
				$"..".add_child(rtCollide)
				rtClone.global_position = Vector2((sprite.global_position.x + screen_size.x), sprite.global_position.y)
				rtCollide.global_position = rtClone.global_position
			else:
				rtClone.global_position = Vector2((sprite.global_position.x + screen_size.x), sprite.global_position.y)
				rtCollide.global_position = rtClone.global_position
		elif rtClone != null:
			rtClone.queue_free()
			rtClone = null
			rtCollide.queue_free()
			rtCollide = null
