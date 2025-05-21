extends Area2D

@onready var explosion_animation = preload("res://scenes/explosion_animation.tscn").instantiate()
@export var damage = 100


func _on_area_entered(area: Area2D) -> void:
	AudioManager.play_sfx_string("explosion")
	get_tree().current_scene.add_child(explosion_animation)
	queue_free()
	

	
	
 
