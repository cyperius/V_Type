extends Area2D

@export var damage : int = 1000

func _ready() -> void:
	var skin = get_child(0) as Sprite2D
	skin.texture = load("res://assets/graphic_elements/game_world/golden_girder_256x171.png")
