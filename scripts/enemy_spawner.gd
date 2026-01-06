extends Node2D

signal boss_defeated
signal level_finished(level_nr: int)
signal enemy_spawned(enemy: Node)
signal incoming_boss


@export var timer_basic_wait_time : int = 3
@export var timer2_basic_wait_time : int = 4


@export var level_boss : PackedScene
@export var basic_spawn_rate : int = 1
@export var enemy1 : PackedScene
@export var enemy2_with_path : PackedScene
@export var enemy3 : PackedScene
@export var enemy4_with_path : PackedScene
@export var enemy5 : PackedScene
@export var enemy6_with_path : PackedScene
@export var enemy7 : PackedScene
@export var enemy8_with_path : PackedScene


@onready var timer = $Timer
@onready var timer2 = $Timer2
var timer3 : Timer # so wird timer3 als globale Variable definiert - das klappt unabhängig davon
# ob sie tatsächlcih mit einem Wert ausgestattet wird. Somit kann, wenn ihr denn später in diesem Skript einen 
# Wert / eine referenz zugeordnet wird darauf zugegriffen werden
@onready var randomizer = RandomNumberGenerator.new()
@onready var enemy_blueprint = preload("res://enemies&obstacles/enemy_1.tscn")
@onready var path_enemy_blueprint = preload("res://enemies&obstacles/enemy_with_path.tscn")
@onready var level = $".."


# Vorteil dieser Schreibweise: Die Verbindung stimmt, egal welcher Szene dieses
# Skript angehängt ist, solange es dort auch einen EnemiesContainer gibt
@onready var enemies_container = get_parent().get_node("EnemiesContainer")
@onready var enemy_positions_node = $SpawnPositions

@onready var enemy_positions = enemy_positions_node.get_children()
# so erhält man einen array, mit den child_nodes des Node SpawnPositions 
# (welcher hier der Variable enemy_positions_node zugewiesen ist)
# mit einer weiteren Hierarchie/ordnungsebene für Gruppen von Marker2DNodes 
# könnte man auch verschiedene Phasen zuordnen (z.B. enemy_positions_wave1... )

@onready var enemy_counter : int = 0
var number_of_players : int 
var spawn_rate : float
var boss_spawned = false
var current_level : Node
var at_least_one_enemy_spawned := false
var spawn_positions_count

func _ready() -> void:
	spawn_positions_count = enemy_positions.size()
	current_level = get_parent()
	number_of_players = 1 # damit sicher von Anfang an eine spawnrate gesetzt werden kann
	set_spawn_rate()
	timer.timeout.connect(_on_timer_timeout)
	timer2.timeout.connect(_on_timer2_timeout)
	if self.has_node("%Timer3"):
		timer3 = get_node("%Timer3")
		timer3.timeout.connect(_on_timer3_timeout)
	
	
func set_spawn_rate(spawn_rate_multiplyer: int = 1) -> void:
	# default Wert (für den fall, dass noch kein Spieler im Spiel ist)
	# evtl. funktioniert die Anpassung der Spawn rate, wenn die Spieleranzahl ändert
	# bzw, deren reale Umsetzung noch nicht
	number_of_players = Global.player_ships.size()
	# basic_spawn_rate bei '1' (pro Spieler) starten und pro Durchlauf um 0.2 erhöhen
	# zusätzliche Anpassung durch spawn_rate_multiplayer Parameter möglich 
	spawn_rate = (0.8 + GameManager.loop_counter/5) * number_of_players * basic_spawn_rate * spawn_rate_multiplyer
	# Je höher die spawn_rate umso kürzer die spawn_time
	timer.wait_time = timer_basic_wait_time / spawn_rate
	timer2.wait_time = timer2_basic_wait_time / spawn_rate
	#print("spawn_rate = ", spawn_rate)
	#print("number of players = ", number_of_players)
	#print("the timer1 wait_time is: ", timer.wait_time)
	#print("the timer2 wait_time is: ", timer2.wait_time)


func _on_timer_timeout():
	at_least_one_enemy_spawned = true
	# print("(enemy.gd): timeout -> normaler enemy?")
	var spawn_pos_nr = randi_range(1, spawn_positions_count-1)
	var enemy = enemy1.instantiate()
	enemy.current_level = level # aktuellen Level-Referenz auf den enemy übertragen (dort gibt es eine entsprechende Variable)
	enemy.position = enemy_positions[spawn_pos_nr].global_position
	emit_signal("enemy_spawned", enemy)
	# die PackedScene "res://scenes/enemy_1.tscn" welche welche oebn der Variable 
	# "enemy_blueprint" zugeordnet wurde, wird nun istantiiert ...5
	enemies_container.add_child(enemy)
	get_tree().current_scene.name 

	self.get_path()

	get_parent().get_path()
	get_instance_id()
	# und nun noch im Szenenbaum der aktuellen Szene (also die, welcher dieses Skript angehängt ist) 
	# als child zugeordnet (erst dann wird die Szene auch im Spiel manifestiert)
	
	#print(enemy.position)
	enemy_counter += 1
	#enemy.speed += enemy_counter * 10
	#print("enemies: ", enemy_counter, "enemy_speed: ", enemy.speed)
	
	
func _on_timer2_timeout():
	if enemy2_with_path == null:
		return
	else:
		var spawn_pos_nr = randi_range(1, spawn_positions_count-1)
		var path_enemy = enemy2_with_path.instantiate()
		emit_signal("enemy_spawned", path_enemy)
		# die PackedScene "res://scenes/enemy_1.tscn" welche welche oebn der Variable 
		# "enemy_blueprint" zugeordnet wurde, wird nun istantiiert ...
		enemies_container.add_child(path_enemy)
		# und nun noch im Szenenbaum der aktuellen Szene (also die, welcher dieses Skript angehängt ist) 
		# als child zugeordnet (erst dann wird die Szene auch im Spiel manifestiert)
		path_enemy.position.y = enemy_positions[spawn_pos_nr].position.y/2.8
		enemy_counter += 1
	
func _on_timer3_timeout() -> void:
	at_least_one_enemy_spawned = true
	# print("(enemy.gd): timeout -> normaler enemy?")
	var spawn_pos_nr = randi_range(1, spawn_positions_count-1)
	var enemy = enemy3.instantiate()
	enemy.current_level = level # aktuellen Level-Referenz auf den enemy übertragen (dort gibt es eine entsprechende Variable)
	enemy.position = enemy_positions[spawn_pos_nr].global_position
	emit_signal("enemy_spawned", enemy)
	# die PackedScene "res://scenes/enemy_1.tscn" welche welche oebn der Variable 
	# "enemy_blueprint" zugeordnet wurde, wird nun istantiiert ...5
	enemies_container.add_child(enemy)
	get_tree().current_scene.name 

	self.get_path()

	get_parent().get_path()
	get_instance_id()
	# und nun noch im Szenenbaum der aktuellen Szene (also die, welcher dieses Skript angehängt ist) 
	# als child zugeordnet (erst dann wird die Szene auch im Spiel manifestiert)
	
	#print(enemy.position)
	enemy_counter += 1



func here_comes_the_boss():
	boss_spawned = true
	emit_signal("incoming_boss")
	enemy_counter += 1
	timer.stop()
	timer2.stop()
	if timer3:
		timer3.stop()
	
	# level_boss ist eine Exportvariable, der im Inspector eine PackedScene zugeorndet wird
	# Daraus wird nun eine Instanz erstellt mit Name boss erstellt
	# zuerst wird noch geprüft, ob ein level_boss gesetzt wurde
	if level_boss == null:
		_on_boss_defeated() # falls kein Boss gesetzt wurde, lösen wir direkt das defeated_signal aus
		# damit der Level beendet wird. 14.12.22025 evtl. Bezeichnung ändern oder separates Signal zum levelbeeenden?
	else: # wenn also ein Boss für level_boss gesetzt wurde (ganz oben "preload")
		var boss = level_boss.instantiate()
		# und dann die wird level_boss als child_Szene zur laufenden Szene hinzugefügt
		get_tree().current_scene.add_child(boss)
		boss.connect("boss_defeated", Callable(self, "_on_boss_defeated"))
		boss.global_position = Vector2(5000, 1100) # 7000, 1100
		# kleines Manko: wenn die Zahl der Spielr nach dem Spawnrn ändert, bleibt health unverändert
		boss.health_points = boss.health_points * number_of_players


func _on_boss_defeated():
	print("enemy_spawner_received_boss_defeated")
	emit_signal("boss_defeated")
	
