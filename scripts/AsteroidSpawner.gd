extends Node2D  # MainScene basiert auf Node2D

@onready var asteroid : PackedScene = preload("res://scenes/rigid_asteroid.tscn")
@onready var spawn_timer = $Timer
@onready var ui : Control = $UI
@onready var astroid_level : Node2D = $".."
# mit jedem Durchspiel wird die spawn_rate um 0.2 erhöht
@onready var spawn_rate : float = 0.8 + GameManager.loop_counter/5
@onready var asteroids_amount : float = 0.5 + GameManager.loop_counter / 2
@onready var asteroid_speed_level : float = 0.8 * GameManager.loop_counter / 5

const SCREEN_SIZE = Vector2(3840, 2160)

var asteroid_counter = 0

signal asteroid_destroyed(size)




func _ready():
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	randomize()
	asteroid_destroyed.connect(Callable(get_parent(), "_on_destroyed_asteroid"))
	spawn_timer.wait_time = 0.25 / spawn_rate
	
	
func _on_spawn_timer_timeout() -> void:
	var new_asteroid = asteroid.instantiate()
	print("spawn")
	
	# Bei jedem Durchgang, wird die Menge der Asteroiden um Faktor 0.5 erhöht 
	if asteroid_counter < 100 * asteroids_amount:
		# spawn time verküzt sich laufend
		spawn_timer.wait_time -= 0.0003 * spawn_timer.wait_time
		
	if asteroid_counter >= 100 * asteroids_amount and asteroid_counter < 150 * asteroids_amount:
		spawn_timer.wait_time -= 0.00045 * spawn_timer.wait_time
	if asteroid_counter >= 100 * asteroids_amount:
		if randi_range(1, 3) == 3:
			var pos_from_top = Vector2(randf_range(1800, 3500), randf_range(-100, -300))
			new_asteroid.position = pos_from_top
			# Setze hier die gewünschten Bewegungsparameter:
			new_asteroid.direction = Vector2.RIGHT.rotated(randf_range(deg_to_rad(110), deg_to_rad(180)))
			# wird bei jedem Durchspiel schneller, siehe var asteroid_speed_level
			new_asteroid.speed = 550 * asteroid_speed_level
			# Aktualisiere den linear_velocity, wenn nötig:
			new_asteroid.linear_velocity = new_asteroid.direction * new_asteroid.speed
			
	if asteroid_counter >= 150 * asteroids_amount:
		spawn_timer.wait_time -= 0.0007 * spawn_timer.wait_time
		if randi_range(1, 3) == 2:
			var pos_from_under = Vector2(randf_range(200, 1700), randf_range(2150, 2350))
			new_asteroid.position = pos_from_under
			# Setze hier die gewünschten Bewegungsparameter:
			new_asteroid.direction = Vector2.RIGHT.rotated(randf_range(deg_to_rad(290), deg_to_rad(220)))
			new_asteroid.speed = 700 * asteroid_speed_level
			# Aktualisiere den linear_velocity, wenn nötig:
			new_asteroid.linear_velocity = new_asteroid.direction * new_asteroid.speed
			
	if asteroid_counter >= 300 * asteroids_amount:
		spawn_timer.stop()
	
	add_child(new_asteroid)
	asteroid_counter += 1
	
	
func _on_asteroid_destroyed(size) -> void:
	emit_signal("asteroid_destroyed", size)
		
	
func _process(delta: float) -> void:
	pass
	
 
