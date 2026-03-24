class_name DamageExplosion
extends Area2D

@export var explosion_area_to_be := Vector2 (40, 40)
@onready var visual_damage_explosion: Sprite2D = %visual_damage_explosion
@onready var damage_collision_shape: CollisionShape2D = %damage_collision_shape

@export var damage : int = 800
var radius : float



func _ready() -> void:
	add_to_group("damage_area")
	add_to_group("enemies")
	
	var circle_shape = CircleShape2D.new()
	damage_collision_shape.shape = circle_shape

	var explosion_tween = create_tween() # das ExplosionsSprite wächst per tween auf die Endgrösse
	explosion_tween.set_parallel()
	explosion_tween.tween_method(_set_visual_scale, Vector2(1, 1), explosion_area_to_be, 5)
	explosion_tween.tween_method(_set_damage_radius, 26, explosion_area_to_be.x * 26, 5)

	await explosion_tween.finished # wenn der tween vorbei ist wird der enemy direkt gelöscht - nicht via die() Funktion
	queue_free()
	
	
func _set_visual_scale(area_scale: Vector2) -> void:
	visual_damage_explosion.scale = area_scale
	
	
func _set_damage_radius(circle_radius) -> void:
	damage_collision_shape.shape.radius = circle_radius
	
