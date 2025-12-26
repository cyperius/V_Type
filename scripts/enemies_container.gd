extends Node2D

signal change_direction
signal chance_of_behaviour_chance_changed(chance_1_to : int)


func _on_just_touched_boarder():
	emit_signal("change_direction")
