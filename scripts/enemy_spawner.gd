extends Node2D

@onready var timer = $Timer
@onready var timer2 = $Timer2
@onready var randomizer = RandomNumberGenerator.new()
@onready var enemy_blueprint = preload("res://scenes/enemy_1.tscn")
@onready var path_enemy_blueprint = preload("res://scenes/enemy_with_path.tscn")

@onready var enemy_positions_node = $SpawnPositions
@onready var enemy_positions = enemy_positions_node.get_children()
# so erhält man einen array, mit den child_nodes des Node SpawnPositions 
# (welcher hier der Variable enemy_positions_node zugewiesen ist)
@onready var enemy_counter : int = 0


func _ready() -> void:
	timer.timeout.connect(_on_timer_timeout)
	timer2.timeout.connect(_on_timer2_timeout)
	

func _process(delta: float) -> void:
	if enemy_counter == 10:
		here_comes_the_boss()
	

func _on_timer_timeout():
	var spawn_pos_nr = randi_range(0, 5)
	var enemy = enemy_blueprint.instantiate()
	# die PackedScene "res://scenes/enemy_1.tscn" welche welche oebn der Variable 
	# "enemy_blueprint" zugeordnet wurde, wird nun istantiiert ...
	get_tree().current_scene.add_child(enemy)
	# und nun noch im Szenenbaum der aktuellen Szene (also die, welcher dieses Skript angehängt ist) 
	# als child zugeordnet (erst dann wird die Szene auch im Spiel manifestiert)
	enemy.position = enemy_positions[spawn_pos_nr].position
	print(enemy.position)
	enemy_counter += 1
	enemy.speed += enemy_counter * 10
	#print("enemies: ", enemy_counter, "enemy_speed: ", enemy.speed)
	
	
func _on_timer2_timeout():
	var spawn_pos_nr = randi_range(2, 5)
	var path_enemy = path_enemy_blueprint.instantiate()
	# die PackedScene "res://scenes/enemy_1.tscn" welche welche oebn der Variable 
	# "enemy_blueprint" zugeordnet wurde, wird nun istantiiert ...
	get_tree().current_scene.add_child(path_enemy)
	# und nun noch im Szenenbaum der aktuellen Szene (also die, welcher dieses Skript angehängt ist) 
	# als child zugeordnet (erst dann wird die Szene auch im Spiel manifestiert)
	path_enemy.position.y = enemy_positions[spawn_pos_nr].position.y/2.8
	enemy_counter += 1
	
	
func here_comes_the_boss():
	enemy_counter += 1
	timer.stop()
	#await get_tree().create_timer(5.0).timeout
	AudioManager.fade_out(5)
	var boss = preload("res://scenes/boss_1.tscn").instantiate()
	get_tree().current_scene.add_child(boss)
	boss.global_position = Vector2(7000, 1100)

	#print(enemy.global_position)
	
