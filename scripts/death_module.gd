class_name DeathModule extends Node2D
signal enemy_destroyed

@export var explosion_animation_scene : PackedScene = preload("res://game_world/explosion_animation.tscn")
@export var explosion_size_x : float = 5
@export var explosion_size_y : float = 5

@onready var death_module_owner = $".." # Referenz zum Parent
var path_node_to_delete : Path2D # 28.4.26 : Referenz wird in raedy-Funktion des Path2D Nodes gesetzt


func _ready() -> void:
	enemy_destroyed.connect(GameManager._on_enemy_destroyed)
	
	
func die() -> void:
	var explosion_animation = explosion_animation_scene.instantiate()
	explosion_animation.global_position = global_position
	explosion_animation.scale = Vector2(explosion_size_x, explosion_size_y)
	get_tree().current_scene.add_child(explosion_animation)
	hide()
	await get_tree().create_timer(0.05).timeout
	if death_module_owner.path2d_origin == true:
		# zu allfälligem path2D (Ex-)Parent verbinden um dort löschen zu triggern
		enemy_destroyed.connect(path_node_to_delete._on_following_path_enemy_destroyed)
		enemy_destroyed.emit() # zu allfälligem path2D (Ex-)Parent verbinden um dort löschen zu triggern
		death_module_owner.queue_free()
