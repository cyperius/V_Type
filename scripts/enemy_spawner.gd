extends Node2D

@onready var timer = $Timer
@onready var timer2 = $Timer2
@onready var randomizer = RandomNumberGenerator.new()
@onready var enemy_blueprint = preload("res://scenes/enemy_1.tscn")
@onready var path_enemy_blueprint = preload("res://scenes/enemy_with_path.tscn")
@onready var level_1 = $".."
@onready var enemy_positions_node = $SpawnPositions
@onready var enemy_positions = enemy_positions_node.get_children()
# so erhält man einen array, mit den child_nodes des Node SpawnPositions 
# (welcher hier der Variable enemy_positions_node zugewiesen ist)
@onready var enemy_counter : int = 0
#spawn Rate bei '1' starten und pro Durchlauf um 0.2 erhöhen
@onready var spawn_rate : float = 0.8 + GameManager.loop_counter/5
signal boss_defeated
signal level_finished(level_nr: int)



func _ready() -> void:
	timer.timeout.connect(_on_timer_timeout)
	timer2.timeout.connect(_on_timer2_timeout)
	timer.wait_time = 2 / spawn_rate
	timer2.wait_time = 3 / spawn_rate
	

func _process(delta: float) -> void:
	if enemy_counter == level_1.amount_of_enemies:
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
	#print(enemy.position)
	enemy_counter += 1
	#enemy.speed += enemy_counter * 10
	#print("enemies: ", enemy_counter, "enemy_speed: ", enemy.speed)
	
	
func _on_timer2_timeout():
	var spawn_pos_nr = randi_range(1, 5)
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
	timer2.stop()
	#await get_tree().create_timer(5.0).timeout
	AudioManager.fade_out(5)
	var boss = preload("res://scenes/boss_1.tscn").instantiate()
	get_tree().current_scene.add_child(boss)
	boss.connect("boss_defeated", Callable(self, "_on_boss_defated"))
	boss.global_position = Vector2(7000, 1100)

func _on_boss_defated():
	emit_signal("boss_defeated")
	
