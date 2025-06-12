extends Node2D  # MainScene basiert auf Node2D

@onready var audio_stream_player = $AudioStreamPlayer
@onready var bg = $background_Control
@onready var asteroid : PackedScene = preload("res://scenes/rigid_asteroid.tscn")
@onready var spawn_timer = $Timer
@onready var asteroids_spawner = $AsteroidSpawner
@onready var score: int = 0
@onready var asteroid_amount = 0.75 + GameManager.loop_counter/4

signal level_finished(next_level_nr: int, gained_score: int, gained_energy: int)


func _ready():
	bg.size = Vector2(3860, 2160)  # Falls FullHD-Fenstergröße
	#background.position = Vector2(-1920, -1440)  # Stelle sicher, dass er oben links beginnt
	Global.player_ship.global_position = Vector2(1000, 1000)
	Global.player_ship.mode = Global.player_ship.PlayerMode.FREE
	Global.player_ship.rotation_degrees = 0
	
	
func _process(delta: float) -> void:
	if asteroids_spawner.asteroid_counter == 300 * asteroid_amount:
		await get_tree().create_timer(5).timeout
		emit_signal("level_finished", 3, score, 0)
	
	
