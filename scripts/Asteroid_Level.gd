extends Node2D  # MainScene basiert auf Node2D

@onready var bg = $background_Control
@onready var asteroid : PackedScene = preload("res://scenes/rigid_asteroid.tscn")
@onready var spawn_timer = $Timer
@onready var ui : Control = $Camera2D/CanvasLayer/UI
@onready var asteroids_spawner = $AsteroidSpawner
@onready var score: int = 0


func _ready():
	
	bg.size = Vector2(3860, 2160)  # Falls FullHD-Fenstergröße
	#background.position = Vector2(-1920, -1440)  # Stelle sicher, dass er oben links beginnt
	ui.score.text = str(score)

	AudioManager.play_music("survival_3")
	
	
func _process(delta: float) -> void:
	pass
	ui.asteroids_counter.text = "Asteroids: " + str(asteroids_spawner.asteroid_counter)
	
	
func _on_destroyed_asteroid(size) -> void:
	score += size
	ui.score.text = str(score)
