extends Node2D

@onready var player = get_tree().current_scene.player_space_ship
@export var circle_radius := 200.0
@export var level_soundtrack : AudioStreamWAV
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var timer = $Timer


signal level_finished(next_level_nr: int, gained_score: int, gained_energy: int)



func _ready() -> void:
	# 1. Spieler-Schiff instanziieren
	# var player = player_scene.instantiate()
	# add_child(player)
	player.scale = Vector2(0.2, 0.2)
	timer.timeout.connect(_on_timer_timeout)

	# 2. Circle-Mode aktivieren
	player.mode = player.PlayerMode.CIRCLE

	# 3. Zentrum setzen
	var center_node = $Center
	player.circle_center_position = center_node.global_position

	# 4. Radius setzen
	player.circle_radius = circle_radius

	# 5. Startwinkel auswählen (hier 0 Radiant = rechts außen)
	var start_angle := 0.0
	player.angle = start_angle

	# 6. Position auf dem Kreis berechnen
	player.global_position = center_node.global_position + Vector2(cos(start_angle), sin(start_angle)) * circle_radius

	# 7. Rotation so setzen, dass das Schiff nach innen schaut (angle + PI)
	player.rotation = start_angle + PI

	# 8. Debug-Ausgabe
	print("Level3: Circle_Mode aktiviert. Center=", player.circle_center_position, " Radius=", player.circle_radius)
	
	# 9. Level Ende
func _on_timer_timeout():
	emit_signal("level_finished",1, 0, 0)
