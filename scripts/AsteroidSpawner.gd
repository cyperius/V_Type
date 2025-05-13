extends Node2D  # MainScene basiert auf Node2D

@onready var asteroid : PackedScene = preload("res://scenes/rigid_asteroid.tscn")
@onready var spawn_timer = $Timer
@onready var ui : Control = $UI
@onready var astroid_level : Node2D = $".."

const SCREEN_SIZE = Vector2(3840, 2160)

var asteroid_counter = 0

signal asteroid_destroyed(size)




func _ready():
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	randomize()
	asteroid_destroyed.connect(Callable(get_parent(), "_on_destroyed_asteroid"))
	
	
func _on_spawn_timer_timeout() -> void:
	var new_asteroid = asteroid.instantiate()
	
	if asteroid_counter < 100:
		spawn_timer.wait_time -= 0.0003 * spawn_timer.wait_time
		
	if asteroid_counter >= 100 and asteroid_counter < 150:
		spawn_timer.wait_time -= 0.00045 * spawn_timer.wait_time
	if asteroid_counter >= 100:
		if randi_range(1, 3) == 3:
			var pos_from_top = Vector2(randf_range(1800, 3500), randf_range(-100, -300))
			new_asteroid.position = pos_from_top
			# Setze hier die gewünschten Bewegungsparameter:
			new_asteroid.direction = Vector2.RIGHT.rotated(randf_range(deg_to_rad(110), deg_to_rad(180)))
			new_asteroid.speed = 550  # oder einen anderen Wert, den du nutzen möchtest
			# Aktualisiere den linear_velocity, wenn nötig:
			new_asteroid.linear_velocity = new_asteroid.direction * new_asteroid.speed
			
	if asteroid_counter >= 150:
		spawn_timer.wait_time -= 0.0007 * spawn_timer.wait_time
		if randi_range(1, 3) == 2:
			var pos_from_under = Vector2(randf_range(200, 1700), randf_range(2150, 2350))
			new_asteroid.position = pos_from_under
			# Setze hier die gewünschten Bewegungsparameter:
			new_asteroid.direction = Vector2.RIGHT.rotated(randf_range(deg_to_rad(290), deg_to_rad(220)))
			new_asteroid.speed = 700  # oder einen anderen Wert, den du nutzen möchtest
			# Aktualisiere den linear_velocity, wenn nötig:
			new_asteroid.linear_velocity = new_asteroid.direction * new_asteroid.speed
			
	if asteroid_counter >= 300:
		spawn_timer.stop()
	
	add_child(new_asteroid)
	asteroid_counter += 1
	
	
func _on_asteroid_destroyed(size) -> void:
	emit_signal("asteroid_destroyed", size)
		
	
func _process(delta: float) -> void:
	pass
	
 
