extends Node2D  # MainScene basiert auf Node2D

signal level_finished(next_level_nr: int, gained_score: int, gained_energy: int)
signal enemy_destroyed(score: int, energy: int)

@export var asteroids_amount_basic : int = 300
@onready var audio_stream_player = $AudioStreamPlayer
@onready var bg = $background_Control
@onready var asteroid : PackedScene = preload("res://scenes/rigid_asteroid.tscn")
@onready var spawn_timer = $Timer
@onready var asteroid_spawner: Node2D = %AsteroidSpawner
@onready var score: int = 0
@onready var asteroid_amount = 0.75 + GameManager.loop_counter/4



func _ready():
	asteroid_spawner.enemy_spawned.connect(_on_enemy_spawned)
	bg.size = Vector2(3860, 2160)  # Falls FullHD-Fenstergröße
	##background.position = Vector2(-1920, -1440)  # Stelle sicher, dass er oben links beginnt
	
# ── Spieler vorbereiten: für ALLE registrierten Spieler
	for player_id in Global.player_ships.keys():
		var ship := Global.get_player_ship(player_id)
		if ship == null:
			print("⚠️ Spieler mit ID %d nicht gefunden!" % player_id)
			continue

		# Grundzustand für Levelstart
		ship.mode = ship.PlayerMode.FREE
		ship.rotation_degrees = 0
		ship.collision_mask = (1 << 2) | (1 << 3) | (1 << 4) | (1 << 5)
		ship.collision_layer = 1
	
	
func _process(delta: float) -> void:
	if asteroid_spawner.asteroid_counter == asteroids_amount_basic * asteroid_amount:
		await get_tree().create_timer(10).timeout
		emit_signal("level_finished", 3, score, 0)
	
	
func _on_enemy_spawned(enemy: Node) -> void:
	# print("asteroid_destroyed_sigbal_connected") check
	enemy.enemy_destroyed.connect(_on_enemy_destroyed)


func _on_enemy_destroyed(score: int, energy:int):
	print("take the fucking score!", score)
	emit_signal("enemy_destroyed", score, energy)
