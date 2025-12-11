extends Node2D

signal change_direction


func _on_just_touched_boarder():
	emit_signal("change_direction")
