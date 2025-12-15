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


func _ready() -> void:
	 
	current_level = get_parent()
	number_of_players = 1
	set_spawn_rate()
	timer.timeout.connect(_on_timer_timeout)
	timer2.timeout.connect(_on_timer2_timeout)
	
	
func set_spawn_rate(spawn_rate: int =1) -> void:
	# default Wert (für den fall, dass noch kein Spieler im Spiel ist)
	# evtl. funktioniert die Anpassung der Spawn rate, wenn dei Speielranzahl ändert
	# bzw, deren reale Umsetzung noch nicht
	spawn_rate = basic_spawn_rate
	number_of_players = Global.player_ships.size()
	#spawn Rate bei '1' (pro Spieler) starten und pro Durchlauf um 0.2 erhöhen
	spawn_rate = clamp(1, ((0.8 + GameManager.loop_counter/5) * number_of_players * basic_spawn_rate), 4)
	print("number_of_players = ", number_of_players)
	timer.wait_time = timer_basic_wait_time / spawn_rate
	timer2.wait_time = timer2_basic_wait_time / spawn_rate
	print("spawn_rate = ", spawn_rate, "number of palyers = ", number_of_players)
	print(" is the timer1 waittime: ", timer.wait_time, timer2.wait_time, " ist the timer2 time")


func _process(delta: float) -> void:
	
	# Sicherheitsabfrage, ob mind. 1 enemy gespawnt ist (nur damit genug Zeit da ist um in current_level
	# den aktuellen level zu referenzieren und ob "amount_of_ememies" existiert 
	if at_least_one_enemy_spawned:
		if enemy_counter >= current_level.amount_of_enemies and boss_spawned == false:
			here_comes_the_boss()

func _on_timer_timeout():
	at_least_one_enemy_spawned = true
	print("timeout -> normaler enemy?")
	var spawn_pos_nr = randi_range(0, 5)
	var enemy = enemy1.instantiate()
	emit_signal("enemy_spawned", enemy)
	# die PackedScene "res://scenes/enemy_1.tscn" welche welche oebn der Variable 
	# "enemy_blueprint" zugeordnet wurde, wird nun istantiiert ...
	enemies_container.add_child(enemy)
	# und nun noch im Szenenbaum der aktuellen Szene (also die, welcher dieses Skript angehängt ist) 
	# als child zugeordnet (erst dann wird die Szene auch im Spiel manifestiert)
	enemy.position = enemy_positions[spawn_pos_nr].position
	#print(enemy.position)
	enemy_counter += 1
	#enemy.speed += enemy_counter * 10
	#print("enemies: ", enemy_counter, "enemy_speed: ", enemy.speed)
	
	
func _on_timer2_timeout():
	var spawn_pos_nr = randi_range(1, 5)
	var path_enemy = enemy2_with_path.instantiate()
	emit_signal("enemy_spawned", path_enemy)
	# die PackedScene "res://scenes/enemy_1.tscn" welche welche oebn der Variable 
	# "enemy_blueprint" zugeordnet wurde, wird nun istantiiert ...
	enemies_container.add_child(path_enemy)
	# und nun noch im Szenenbaum der aktuellen Szene (also die, welcher dieses Skript angehängt ist) 
	# als child zugeordnet (erst dann wird die Szene auch im Spiel manifestiert)
	path_enemy.position.y = enemy_positions[spawn_pos_nr].position.y/2.8
	enemy_counter += 1
	
	
func here_comes_the_boss():
	boss_spawned = true
	emit_signal("incoming_boss")
	enemy_counter += 1
	timer.stop()
	timer2.stop()
	
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
		boss.global_position = Vector2(7000, 1100)
		# kleines Manko: wenn die Zahl der Spielr nach dem Spawnrn ändert, bleibt health unverändert
		boss.health = boss.health * number_of_players

func _on_boss_defeated():
	emit_signal("boss_defeated")
	
