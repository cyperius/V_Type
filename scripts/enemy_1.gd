extends Area2D

@onready var explosion_animation = preload("res://scenes/explosion_animation.tscn").instantiate()
@export var damage = 100
@export var speed = 600


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	add_to_group("one_hit_enemies")
	add_to_group("enemies")
	
	

func _on_area_entered(area: Area2D) -> void:
	AudioManager.play_sfx_string("explosion")
	get_tree().current_scene.add_child(explosion_animation)
	explosion_animation.position = global_position
	queue_free()
	

	
func _process(delta: float) -> void:
	position.x -= delta * speed
	
	
