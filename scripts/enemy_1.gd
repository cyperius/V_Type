extends Area2D

signal enemy_destroyed(score: int, energy: int)

@export var shot_sound : AudioStream 
@export var shot_scene : PackedScene
@export var damage = 100
@export var basic_speed : int = 50
@export var score_count : int = 100
@export var energy_left : int = 5

@onready var explosion_animation = preload("res://scenes/explosion_animation.tscn").instantiate()
@onready var explosion_size : float = 5
@onready var speed = basic_speed * GameManager.loop_counter
@onready var audio_stream_player_2d = $AudioStreamPlayer2D
@onready var _gun_point: Marker2D = %GunPoint

var shoot_timer = Timer.new()
var evasive_mode_on = false


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	add_to_group("one_hit_enemies")
	add_to_group("enemies")
	add_to_group("evaders")
	add_child(shoot_timer)
	shoot_timer.wait_time = 2
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	shoot_timer.start()
	audio_stream_player_2d.stream = shot_sound
	
	
func _on_area_entered(area: Area2D) -> void:
	#AudioManager.play_sfx_string("explosion")
	get_tree().current_scene.add_child(explosion_animation)
	explosion_animation.position = global_position
	explosion_animation.scale = Vector2(explosion_size, explosion_size)
	emit_signal("enemy_destroyed", score_count, energy_left)
	hide()
	await get_tree().create_timer(0.05).timeout
	queue_free()
	
	
func _process(delta: float) -> void:
	if evasive_mode_on:
		position.y += delta * 950
	position.x -= delta * speed
	

func _on_shoot_timer_timeout():
	audio_stream_player_2d.play()
	var shot = shot_scene.instantiate()
	shot.global_position = _gun_point.global_position
	get_parent().add_child(shot)
