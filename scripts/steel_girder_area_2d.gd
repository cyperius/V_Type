extends Area2D

@export var damage := 1000

func _ready() -> void:
	add_to_group("obstacles")
