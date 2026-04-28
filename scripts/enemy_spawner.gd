class_name EnemySpawner extends Node2D

signal boss_defeated
signal level_finished(level_nr: int)
signal enemy_spawned(enemy: Node)
signal incoming_boss


@export var level_boss: PackedScene
@export var basic_spawn_rate: int = 1

@export_group("Enemy Type 1")
@export var enemy_type_1_scene: PackedScene
@export var enemy_type_1_wait_time: float = 3.0
@export var enemy_type_1_wave: bool = false
@export var enemy_type_1_wave_amount: int = 4
@export var enemy_type_1_is_path_enemy: bool = false

@export_group("Enemy Type 2")
@export var enemy_type_2_scene: PackedScene
@export var enemy_type_2_wait_time: float = 4.0
@export var enemy_type_2_wave: bool = false
@export var enemy_type_2_wave_amount: int = 4
@export var enemy_type_2_is_path_enemy: bool = false

@export_group("Enemy Type 3")
@export var enemy_type_3_scene: PackedScene
@export var enemy_type_3_wait_time: float = 5.0
@export var enemy_type_3_wave: bool = false
@export var enemy_type_3_wave_amount: int = 4
@export var enemy_type_3_is_path_enemy: bool = false

@export_group("Enemy Type 4")
@export var enemy_type_4_scene: PackedScene
@export var enemy_type_4_wait_time: float = 6.0
@export var enemy_type_4_wave: bool = false
@export var enemy_type_4_wave_amount: int = 4
@export var enemy_type_4_is_path_enemy: bool = false


@onready var randomizer := RandomNumberGenerator.new()
@onready var level := $".."
@onready var enemies_container := get_parent().get_node("EnemiesContainer")
@onready var enemy_positions_node := $SpawnPositions
@onready var level_center: Marker2D

var enemy_positions: Array
var spawn_positions_count: int
var number_of_players: int = 1
var spawn_rate: float
var boss_spawned := false
var at_least_one_enemy_spawned := false
var enemy_counter: int = 0
var current_level: Node

# Dynamisch erstellte Timer
var active_timers: Array[Timer] = []
# Zuordnung Timer-Index -> Config Dictionary
var timer_to_config: Dictionary = {}


func _ready() -> void:
	enemy_positions = enemy_positions_node.get_children()
	spawn_positions_count = enemy_positions.size()
	current_level = get_parent()

	if level.has_node("Center"):
		level_center = level.get_node("Center")

	number_of_players = 1
	set_spawn_rate()
	_setup_enemy_timers()


func _setup_enemy_timers() -> void:
	var all_configs: Array = [
		{"scene": enemy_type_1_scene, "wait_time": enemy_type_1_wait_time,
		 "wave": enemy_type_1_wave, "wave_amount": enemy_type_1_wave_amount,
		 "is_path_enemy": enemy_type_1_is_path_enemy},
		{"scene": enemy_type_2_scene, "wait_time": enemy_type_2_wait_time,
		 "wave": enemy_type_2_wave, "wave_amount": enemy_type_2_wave_amount,
		 "is_path_enemy": enemy_type_2_is_path_enemy},
		{"scene": enemy_type_3_scene, "wait_time": enemy_type_3_wait_time,
		 "wave": enemy_type_3_wave, "wave_amount": enemy_type_3_wave_amount,
		 "is_path_enemy": enemy_type_3_is_path_enemy},
		{"scene": enemy_type_4_scene, "wait_time": enemy_type_4_wait_time,
		 "wave": enemy_type_4_wave, "wave_amount": enemy_type_4_wave_amount,
		 "is_path_enemy": enemy_type_4_is_path_enemy},
	]

	for config_data in all_configs: # Für jedes Element (dictionary) im Array "all_configs"...
		if config_data["scene"] == null: # Wenn der dictionary-key "scene" keinen Wert zugeordnet...
			continue # ... hat, überspringe dieses Element
		# ansonsten kreiere und konfiguriere einen timer 
		var new_timer := Timer.new() #
		new_timer.wait_time = config_data["wait_time"]
		new_timer.one_shot = false

		# kreiere die Variable "config_index"(int), die der Grösse des Arrays
		# active_timers entspricht und füge den gerade kreierten timer hinzu
		var config_index := active_timers.size()
		active_timers.append(new_timer)
		
		# kreiere im Dictionary "timer_to_config" einen key(int), welcher dem 
		# Wert der gerade kreierten Variable "config_index" entspricht (Hinweis:
		# da dieser Wert jew. vor dem hinzufügen des neuen Timers erfolgt, ist die
		# index-Zahl für den ersten Timer 0, für den zweiten 1, usw.)...
		timer_to_config[config_index] = config_data # und ordner diesem key
		# das aktuelle Element (also den aktuellen "timer-dictionary" mit den im
		# Inspector gesetzten Konfigurationsdaten) als value zu

		add_child(new_timer) # der Timer wird zur Szene hinzugefügt
		# und sein timeout-Signal wird mit der zugehörigen Methode verbunden
		# Dies ist _on_enemy_timer_timeout.config_index
		new_timer.timeout.connect(_on_enemy_timer_timeout.bind(config_index))
		new_timer.start() # und dder timer wird gestartet

# Wenn ein timeout für Timer_x (timer.config_index) kommt, dann...
func _on_enemy_timer_timeout(config_index: int) -> void:
	# ...breche ab, falls der config_index dieses Timers im Dictionary 
	# timer_to_config" nicht als key existieren sollte (nur eine Sicherheitsabfrage)
	if not timer_to_config.has(config_index):
		return
	
	# Kreiere eine Variable "config_data" und ordne ihr den Wert zu, der  im 
	# timer-Dictionary dem value entspricht, der zum key mit der aktuellen Indexzahl 
	# (welcher dieser methode als Argument mitgegeben wurde) gehört
	var config_data: Dictionary = timer_to_config[config_index]

	if config_data["scene"] == null: # Falls Keine Gegner-Szene gesetzt : Abbruch
		return

	at_least_one_enemy_spawned = true # Wichtig für timimg im Zusammenspiel
	# mit level_base.gd (dort wird der Boolean geprüft)

	if config_data["wave"] and config_data["is_path_enemy"]:
		# Welle aus Path-Enemies: jeder bekommt seine eigene Y-Position
		_spawn_path_enemy_wave(config_data["scene"], config_data["wave_amount"] * number_of_players)
	elif config_data["wave"]:
		var spawn_position := _get_random_spawn_position()
		_spawn_wave(config_data["scene"], config_data["wave_amount"] * number_of_players, 0.5, spawn_position)
	elif config_data["is_path_enemy"]:
		_spawn_path_enemy(config_data["scene"])
	else:
		_spawn_single_enemy(config_data["scene"])


func set_spawn_rate(spawn_rate_multiplier: int = 1) -> void:
	number_of_players = Global.player_ships.size()
	spawn_rate = (0.8 + GameManager.loop_counter / 5.0) * number_of_players * basic_spawn_rate * spawn_rate_multiplier

	for timer_index in active_timers.size():
		var active_timer: Timer = active_timers[timer_index]
		var base_wait_time: float = timer_to_config[timer_index]["wait_time"]
		active_timer.wait_time = base_wait_time / spawn_rate


func _spawn_single_enemy(enemy_scene: PackedScene) -> void:
	var spawn_pos_nr := randi_range(0, spawn_positions_count - 1)
	var enemy := enemy_scene.instantiate()
	enemy.global_position = enemy_positions[spawn_pos_nr].global_position

	if "current_level" in enemy:
		enemy.current_level = level

	if "level_center_orientation" in enemy and level_center != null:
		var direction_to_center := Vector2.ZERO
		direction_to_center.x = -1.0 if enemy.global_position.x > level_center.global_position.x else 1.0
		direction_to_center.y = -1.0 if enemy.global_position.y > level_center.global_position.y else 1.0
		enemy.direction = direction_to_center

	emit_signal("enemy_spawned", enemy)
	enemies_container.add_child(enemy)
	enemy_counter += 1


func _spawn_path_enemy(enemy_scene: PackedScene) -> void:
	var spawn_pos_nr := randi_range(1, spawn_positions_count - 1)
	var path_enemy := enemy_scene.instantiate()
	emit_signal("enemy_spawned", path_enemy)
	path_enemy.position.y = enemy_positions[spawn_pos_nr].position.y / 2.8
	enemies_container.add_child(path_enemy)
	enemy_counter += 1


func _spawn_path_enemy_wave(enemy_scene: PackedScene, amount: int) -> void:
	for _number in range(amount):
		var spawn_pos_nr := randi_range(1, spawn_positions_count - 1)
		var path_enemy := enemy_scene.instantiate()
		emit_signal("enemy_spawned", path_enemy)
		#path_enemy.position.y = enemy_positions[spawn_pos_nr].position.y / 2.8
		enemies_container.add_child(path_enemy)
		enemy_counter += 1

func _get_random_spawn_position() -> Vector2:
	var spawn_pos_nr := randi_range(0, spawn_positions_count - 1)
	return enemy_positions[spawn_pos_nr].global_position


func _spawn_wave(enemy_to_spawn: PackedScene, amount: int, pause_between_spawns: float, spawn_position: Vector2) -> void:
	for _number in range(1, amount):
		var spawning_enemy := enemy_to_spawn.instantiate()
		emit_signal("enemy_spawned", spawning_enemy)
		spawning_enemy.global_position = spawn_position
		enemies_container.add_child(spawning_enemy)
		enemy_counter += 1


func here_comes_the_boss() -> void:
	boss_spawned = true
	emit_signal("incoming_boss")
	enemy_counter += 1

	for active_timer in active_timers:
		active_timer.stop()

	if level_boss == null:
		_on_boss_defeated()
	else:
		var boss := level_boss.instantiate()
		boss.global_position = Vector2(5000, 1100)
		get_tree().current_scene.add_child(boss)
		boss.connect("boss_defeated", Callable(self, "_on_boss_defeated"))
		boss.health_points = boss.health_points * number_of_players


func _on_boss_defeated() -> void:
	emit_signal("boss_defeated")
