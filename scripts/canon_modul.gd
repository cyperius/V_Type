class_name CanonModule
extends Node2D



@export var muzzle_firing_color : Color
@export var muzzle_color : Color
@export var cease_fire_time : float
@export var bullet_szene : PackedScene
@export var shots_per_attack : int
@onready var break_between_shots_timer = Timer.new()
@export var break_between_shots_time : float
@export var shot_direction : Vector2
@onready var aim: Marker2D = $Aim
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var cease_fire_timer = Timer.new() 



func _ready() -> void:
	add_child(break_between_shots_timer)
	add_child(cease_fire_timer)
	cease_fire_timer.start(cease_fire_time)
	cease_fire_timer.timeout.connect(_on_cease_fire_timer_timeout)
	print("farbe = ", sprite_2d.self_modulate)
	sprite_2d.self_modulate = muzzle_color
	
	print("aim node: ", aim)  # Sollte "Aim:<Marker2D#...>" ausgeben, nicht "null"
	# ...

	


func _on_cease_fire_timer_timeout() -> void:
	print("time to fire")
	sprite_2d.self_modulate = muzzle_firing_color
	_shoot(shots_per_attack)
	cease_fire_timer.stop()
	


func _shoot(amount_of_bullets: int) -> void:
	for bullet_nr in range(amount_of_bullets):
		var bullet: Area2D = bullet_szene.instantiate()
		
		shot_direction = global_position.direction_to(aim.global_position)
		bullet.direction = shot_direction
		if shot_direction.x > 0:
			bullet.global_position = global_position + Vector2(190, 0)
		else:
			bullet.global_position = global_position
		get_tree().current_scene.add_child(bullet)
		
	
		break_between_shots_timer.start(break_between_shots_time)
		await break_between_shots_timer.timeout

	cease_fire_timer.start(cease_fire_time)
	sprite_2d.self_modulate = muzzle_color # alternativ ein shots_fired Signal machen, das auslöst, was danch passiert 
