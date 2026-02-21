extends Area2D

@export var damage := 100

func _ready() -> void:
	add_to_group("players")
	
