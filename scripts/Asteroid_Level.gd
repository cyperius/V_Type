extends LevelBase  # MainScene basiert auf Node2D

signal enemy_destroyed(score: int, energy: int)

@export var asteroids_amount_basic : int = 300
@onready var bg = $background_Control
@onready var asteroid : PackedScene = preload("res://enemies&obstacles/rigid_asteroid.tscn")
@onready var spawn_timer = $Timer
@onready var score: int = 0
@onready var asteroid_amount = 0.75 + GameManager.loop_counter/4


func _ready():
	super._ready()
	enemy_spawner.asteroid_destroyed.connect(enemy_spawner._on_asteroid_destroyed)
	flight_mode_switch_initiated.emit()

	
func _process(delta: float) -> void:
	if enemy_spawner.asteroid_counter == asteroids_amount_basic * asteroid_amount:
		await get_tree().create_timer(10).timeout
		emit_signal("level_finished", 3, score, 0)
	
	
func _on_asteroid_destroyed(size) -> void:
	print("take the fucking score!", size)
	emit_signal("enemy_destroyed", 100 * round(size), 100 * round(size))
