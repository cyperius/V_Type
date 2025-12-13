extends Node2D

@export var circle_radius := 200.0
@export var cirle_shot_scene : PackedScene
@export var level_duration_basis : int = 90
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var level_duration = $Timer
@onready var spawn_timer = Timer.new()
@onready var circle_enemy_1 : PackedScene = preload("res://enemies&obstacles/enemy_circle_1.tscn")
@export var winkel_geschwindigkeit : float = 6
@onready var time_delay = 0.8 + GameManager.loop_counter / 5
@onready var center_node = $Center

signal level_finished(next_level_nr: int, gained_score: int, gained_energy: int)


func _ready() -> void:
	# Timer konfigurieren und starten (Level-Logik, unabhängig von Spielern)
	level_duration.wait_time = level_duration_basis * time_delay
	if not level_duration.timeout.is_connected(_on_level_duration_timeout):
		level_duration.timeout.connect(_on_level_duration_timeout)

	spawn_timer.wait_time = 6.0 / time_delay
	if not spawn_timer.timeout.is_connected(_on_spawn_timer_timeout):
		spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	if not spawn_timer.is_inside_tree():
		add_child(spawn_timer)

	spawn_timer.start()
	level_duration.start()

	# Alle bereits vorhandenen Spieler level-spezifisch platzieren
	_place_all_players_in_current_level()


func _place_all_players_in_current_level() -> void:
	# Platziert jeden registrierten Spieler anhand der Level-Logik
	for player_id in Global.player_ships.keys():
		var player := Global.get_player_ship(player_id)
		if player is PlayerShip:
			place_player_in_current_level(player, player_id)

func place_player_in_current_level(player: PlayerShip, player_id: int) -> void:
	# Level 3: Spieler auf Kreisbahn spawnen (Circle-Mode)

	# 1) Modus aktivieren
	player.mode = player.FlightMode.CIRCLE

	# 2) Kreis-Parameter setzen
	player.circle_center_position = center_node.global_position
	player.circle_radius = circle_radius

	# 3) Startwinkel (gleichmäßig nach aktueller Spieleranzahl)
	var active_count : int = max(1, Global.player_ships.size())
	var start_angle: float = 2.0 * PI * float(player_id - 1) / float(active_count)
	player.angle = start_angle + 2 * PI

	# 4) Position + Rotation
	player.global_position = player.circle_center_position + Vector2(cos(start_angle), sin(start_angle)) * player.circle_radius
	player.global_rotation_degrees = start_angle + PI

	# 5) Optional: Level-spezifische Skalierung (rein visuell)
	player.scale = Vector2(0.2, 0.2)
	
	# 6) Level-spezifische skin und Ausrichtung setzen
	player.set_skin("top_down")
	

	# 6) Debug
	print("🌀 Spieler %d im Circle-Mode @ %s (r=%.1f, angle=%.2f)" % [
		player_id, player.circle_center_position, player.circle_radius, start_angle
	])

func _on_level_duration_timeout():
	emit_signal("level_finished", 4, 0, 0)


func _on_spawn_timer_timeout():
	var new_circle_enemy = circle_enemy_1.instantiate()
	add_child(new_circle_enemy)
	
