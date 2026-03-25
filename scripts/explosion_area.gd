class_name DamageExplosion
extends Area2D

@export var explosion_area_to_be := Vector2(30, 30)
@export var explosion_start_radius : float = 26.0
@export var explosion_max_scale := Vector2(40, 40)  
@export var explosion_basic_duration := 0.4
@onready var visual_damage_explosion: Sprite2D = %visual_damage_explosion
@onready var damage_collision_shape: CollisionShape2D = %damage_collision_shape

@export var damage : int = 800
var radius : float
var damage_already_dealt := false # sicherstellen, dass der Scahden nur einaml ausgelöst wird

func _ready() -> void:
	add_to_group("dynamic_damaging_areas")
	
	
	var circle_shape = CircleShape2D.new()
	damage_collision_shape.shape = circle_shape
	
	# Tween-Dauer proportional zur Ladung: früh abgeschossen = schnellere, kleinere Explosion
	var charge_ratio = explosion_area_to_be.x / explosion_max_scale.x
	var tween_duration = explosion_basic_duration * charge_ratio
	print("damage_explosion charge ratio = ", charge_ratio)
	
	var target_radius = explosion_area_to_be.x * explosion_start_radius
	
	var explosion_tween = create_tween()
	explosion_tween.set_parallel()
	explosion_tween.tween_method(_set_damage_radius, explosion_start_radius, target_radius, tween_duration)
	explosion_tween.tween_method(_set_visual_scale, Vector2(1, 1), explosion_area_to_be, tween_duration)
	
	await explosion_tween.finished
	queue_free()

	
func _set_visual_scale(area_scale: Vector2) -> void:
	visual_damage_explosion.scale = area_scale
	
	
func _set_damage_radius(circle_radius) -> void:
	damage_collision_shape.shape.radius = circle_radius
	
