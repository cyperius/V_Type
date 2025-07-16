extends Node2D  # MainScene basiert auf Node2D

signal level_finished(next_level_nr: int, gained_score: int, gained_energy: int)
signal enemy_destroyed(score: int, energy: int)

@onready var audio_stream_player = $AudioStreamPlayer
@onready var boss_timer = $BossTimer
@onready var enemy_spawner: Node2D = $EnemySpawner
@export var amount_of_enemies : int
@onready var enemies_container : Node2D = $EnemiesContainer


func _ready():
	var enemy = preload("res://scenes/enemy_4.tscn").instantiate()
	# alte Signalschreibweise
	enemy_spawner.connect("boss_defeated", Callable(self, "_on_boss_defeated"))
	# neue Signalschreibweise (seit Godot 4.2 werden Signale als Obkete behandelt, daher so schreibbar)
	enemy_spawner.enemy_spawned.connect(_on_enemy_spawned)
	enemy_spawner.incoming_boss.connect(_on_incoming_boss)
	
	# Global.player_ship referenziert die Player_ship Szene mit angehängtem player_ship.gd,
	# und zwar via Global.gd (ein Autoload -> von jedem Skript erreichbar)
	# Mit Zugriff auf die Variable mode und enum PLayer;ode.FREE kann so der Spielmodus gesetzt werden
	Global.player_ship.mode = Global.player_ship.PlayerMode.FREE
	Global.player_ship.rotation_degrees = 0
	Global.player_ship.collision_mask = (1 << 2) | (1 << 3) | (1 << 4) | (1 << 5)
	Global.player_ship.collision_layer = 1
	Global.player_ship.global_position = Vector2 (500, 1000)
	Global.player_ship.scale = Vector2(0.25, 0.25)
	#Global.player_ship.speed = Global.player_ship.max_speed
	Global.player_ship.show()
	enemies_container.add_child(enemy)
	#falls Boss zu fixer Zeit gespawnt werden soll reaktivieren:
	#boss_timer.wait_time = 100 # kann im Editor überschrieben werden
	#boss_timer.timeout.connect(_on_boss_timer_timeout)
	
	
	#background.size = Vector2(3840, 2880)  # Falls FullHD-Fenstergröße
	#background.position = Vector2(-1920, -1440)  # Stelle sicher, dass er oben links beginnt

# Der "Trick" Der frisch gespawnte "enemy" wird als Node übergeben. So kann auf dessen Signal
# "enemy_destroyed" zugegriffen werden
func _on_enemy_spawned(enemy: Node) -> void:
	enemy.enemy_destroyed.connect(_on_enemy_destroyed)
	
	
func _on_enemy_destroyed(score: int, energy: int) -> void:
	emit_signal("enemy_destroyed", score, energy)
	
func _on_boss_timer_timeout():
	pass
	
	
func _on_boss_defeated():
	emit_signal("level_finished", 2, 0, 0)
	print("boss defeated")
	
func _on_incoming_boss() -> void:
	audio_stream_player.stop()
