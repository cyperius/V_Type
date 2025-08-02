extends Node2D

@export var circle_radius := 200.0
@export var cirle_shot_scene : PackedScene
@export var level_duration_basis : int = 90
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var level_duration = $Timer
@onready var spawn_timer = Timer.new()
@onready var circle_enemy_1 : PackedScene = preload("res://scenes/enemy_circle_1.tscn")
@export var winkel_geschwindigkeit : float = 6
@onready var time_delay = 0.8 + GameManager.loop_counter / 5
@onready var center_node = $Center

signal level_finished(next_level_nr: int, gained_score: int, gained_energy: int)

func _ready() -> void:
	level_duration.wait_time = level_duration_basis * time_delay
	level_duration.timeout.connect(_on_level_duration_timeout)

	spawn_timer.wait_time = 6 / time_delay
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	spawn_timer.start()
	level_duration.start()

	# 🔁 Für alle registrierten Spieler im Global-Singleton
	for player_id in Global.player_ships.keys():
		var player = Global.get_player_ship(player_id)
		if player == null:
			continue  # Sicherheitshalber

		# 1. Skalierung anpassen
		player.scale = Vector2(0.2, 0.2)

		# 2. Circle-Mode aktivieren
		player.mode = player.PlayerMode.CIRCLE

		# 3. Player-Zentrum setzen
		player.circle_center_position = center_node.global_position

		# 4. Radius setzen
		player.circle_radius = circle_radius

		# 5. Startwinkel – optional je Spieler anders
		var start_angle : float = PI * 2 * float(player_id - 1) / Global.player_ships.size()
		player.angle = start_angle

		# 6. Position auf dem Kreis berechnen
		player.global_position = center_node.global_position + Vector2(cos(start_angle), sin(start_angle)) * circle_radius

		# 7. Rotation so setzen, dass das Schiff nach innen schaut
		player.rotation = start_angle + PI

		# 8. Debug-Ausgabe
		print("🌀 Spieler %d im Kreis-Modus. Center=%s, Angle=%.2f" % [player_id, player.circle_center_position, start_angle])


func _on_level_duration_timeout():
	emit_signal("level_finished", 4, 0, 0)


func _on_spawn_timer_timeout():
	var new_circle_enemy = circle_enemy_1.instantiate()
	add_child(new_circle_enemy)
