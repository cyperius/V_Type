extends Node2D  # MainScene basiert auf Node2D

signal level_finished(next_level_nr: int, gained_score: int, gained_energy: int)
signal enemy_destroyed(score: int, energy: int)

@onready var audio_stream_player = $AudioStreamPlayer
@onready var boss_timer = $BossTimer
@onready var enemy_spawner: Node2D = $EnemySpawner
@export var amount_of_enemies : int
@onready var enemies_container : Node2D = $EnemiesContainer


func _ready():
	var enemy = preload("res://scenes/enemy_1.tscn").instantiate()
	# alte Signalschreibweise
	enemy_spawner.connect("boss_defeated", Callable(self, "_on_boss_defeated"))
	# neue Signalschreibweise (seit Godot 4.2 werden Signale als Obkete behandelt, daher so schreibbar)
	enemy_spawner.enemy_spawned.connect(_on_enemy_spawned)
	enemy_spawner.incoming_boss.connect(_on_incoming_boss)
	
	# Referenz auf das Schiff des gewünschten Spielers holen (z. B. Spieler 1 oder 2)
	var ship = Global.get_player_ship(1)

	# Sicherheitscheck: Gibt es diesen Spieler überhaupt?
	if ship == null:
		print("⚠️ Spieler mit ID %d nicht gefunden!" % Global.player_id)
		return

	# Setzt den Modus des Spielers (z. B. FREE, CIRCLE) – Achtung: Enum kommt aus dem Spieler selbst!
	ship.mode = ship.PlayerMode.FREE  # Zugriff über das Schiff selbst

	# Zurücksetzen von Rotation und Kollisionsdaten (z. B. bei Respawn oder Level-Start)
	ship.rotation_degrees = 0
	ship.collision_mask = (1 << 2) | (1 << 3) | (1 << 4) | (1 << 5)
	ship.collision_layer = 1
	ship.global_position = Vector2(500, 1000)  # z. B. Startposition für Player 1
	ship.scale = Vector2(0.25, 0.25)

	# Optional: Bewegung zurücksetzen (falls nötig)
	# ship.speed = ship.max_speed

	# Spieler sichtbar machen (z. B. nach Respawn)
	ship.show()

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
