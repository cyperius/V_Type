class_name LevelBase
extends Node2D

signal level_finished(next_level_nr: int, gained_score: int, gained_energy: int)


@export var amount_of_enemies: int
@export var level_nr : int = 1
@export var boss_timer: Timer 
@export_range(0, 270, 90) var player_rotation := 0


@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

@onready var enemy_spawner: Node2D = $EnemySpawner
@onready var enemies_container: Node2D = $EnemiesContainer
@onready var spawned_enemies = 0


func _ready() -> void:
	# Levelstart: Zerstörte IDs zurücksetzen
	Global.reset_round_state()
	# Alle registrierten Spieler ins Level setzen
	_place_all_players_in_current_level()

	# ── Global Signale
	#das Global.roster_changed Signal feuert, wenn die Anz. Spieler geändert hat
	# wenn dies der Fall, werden gewisse Level Pramter angepasst -> func _on_number...
	Global.roster_changed.connect(_on_number_of_players_changed)

	# ── Enemy‑Spawner Signale
	enemy_spawner.connect("boss_defeated", Callable(self, "_on_boss_defeated")) # alte Schreibweise okay
	#enemy_spawner.enemy_spawned.connect(_on_enemy_spawned)
	enemy_spawner.incoming_boss.connect(_on_incoming_boss)

	# Beispiel: einen Gegner ins Container hängen (falls gewünscht)
	var enemy_scene := preload("res://enemies&obstacles/enemy_1.tscn")
	var enemy := enemy_scene.instantiate()
	enemies_container.add_child(enemy)

	# Optional: Boss‑Timer
	#boss_timer.timeout.connect(_on_boss_timer_timeout)


func _place_all_players_in_current_level() -> void:
	for player_id in Global.player_ships.keys():
		var player := Global.get_player_ship(player_id)
		if player is PlayerShip:
			place_player_in_current_level(player, player_id)


func place_player_in_current_level(player: PlayerShip, player_id: int) -> void:
	# Level 1: Standard-LEFT_RIGHT-Mode, Spawn in Viewport-Mitte + Offset

	# 1) Grundzustände
	player.mode = player.PlayerMode.LEFT_RIGHT
	player.rotation_degrees = 0
	player.collision_mask = (1 << 2) | (1 << 3) | (1 << 4) | (1 << 5)
	player.collision_layer = 1

	# 2) Positionierung wie in Main: Mitte + je Spieler versetzter Offset
	var viewport_size: Vector2 = get_viewport_rect().size
	var base_position = viewport_size * 0.05
	var player_offset = Vector2(180, 60 + 240 * (player_id - 1))
	player.global_position = base_position + player_offset

	# 3) Einheitliche Skalierung für Level 1
	player.scale = Vector2(0.25, 0.25)

	# 4) Sichtbar schalten
	player.show()
	
	# 5) je nach Level passende Skin setzen
	player.set_skin("top_down")


func _on_boss_timer_timeout() -> void:
	pass

func _on_boss_defeated() -> void:
	emit_signal("level_finished", level_nr + 1, 0, 0)
	print("boss defeated")


func _on_incoming_boss() -> void:
	audio_stream_player.stop()
	
	
func _on_number_of_players_changed() -> void:
	enemy_spawner.set_spawn_rate()
