extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	$Impact.play() # play sound


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass