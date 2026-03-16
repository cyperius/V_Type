class_name CanonModule
extends Node2D


@onready var cease_fire_timer = Timer.new() 
@export var cease_fire_time : float
@export var bullet_szene : PackedScene
@export var shots_per_attack : int
@onready var break_between_shots_timer = Timer.new()
@export var break_between_shots_time : float
@export var shot_direction : Vector2
@onready var aim: Marker2D = $Aim




func _ready() -> void:
	add_child(break_between_shots_timer)
	add_child(cease_fire_timer)
	cease_fire_timer.start(cease_fire_time)
	cease_fire_timer.timeout.connect(_on_cease_fire_timer_timeout)
	shot_direction = global_position.direction_to(aim)


func _on_cease_fire_timer_timeout() -> void:
	print("time to fire")
	_shoot(shots_per_attack)
	cease_fire_timer.stop()


func _shoot(amount_of_bullets: int) -> void:
	for bullet_nr in range(amount_of_bullets):
		var bullet: Area2D = bullet_szene.instantiate()

		# Problem gelöst. diese prints sind ein schönes Beispiel für gezieltes Debugging
		#print("--- bullet", bullet_nr, "---")
		#print("current_scene:", get_tree().current_scene.name)
		#print("CanonModule global_position:", global_position)
#
		#print("Bullet is_inside_tree VOR add_child:", bullet.is_inside_tree())
		#print("Bullet parent VOR add_child:", bullet.get_parent())

		get_tree().current_scene.add_child(bullet)

		#print("Bullet is_inside_tree NACH add_child:", bullet.is_inside_tree())
		#print("Bullet parent NACH add_child:", bullet.get_parent().name)
		#print("Bullet global_position VOR Zuweisung:", bullet.global_position)
		#print("Bullet local position VOR Zuweisung:", bullet.position)

		bullet.global_position = global_position

		#print("Bullet global_position NACH Zuweisung:", bullet.global_position)
		#print("Bullet local position NACH Zuweisung:", bullet.position)

		break_between_shots_timer.start(break_between_shots_time)
		await break_between_shots_timer.timeout

	cease_fire_timer.start(cease_fire_time)
