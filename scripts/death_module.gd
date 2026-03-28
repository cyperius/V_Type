class_name DeathModule extends Node2D
signal enemy_destroyed

@export var explosion_animation_scene : PackedScene = preload("res://game_world/explosion_animation.tscn")
@export var explosion_size_x : float = 5
@export var explosion_size_y : float = 5

@onready var entity = $".." # Referenz zum Parent


func _ready() -> void:
	enemy_destroyed.connect(GameManager._on_enemy_destroyed)

func die() -> void:
	var explosion_animation = explosion_animation_scene.instantiate()
	explosion_animation.global_position = global_position
	explosion_animation.scale = Vector2(explosion_size_x, explosion_size_y)
	get_tree().current_scene.add_child(explosion_animation)
	hide()
	enemy_destroyed.emit()
	await get_tree().create_timer(0.05).timeout
	get_parent().queue_free()
