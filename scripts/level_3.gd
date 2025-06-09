extends Node2D

@onready var player = get_tree().current_scene.player_space_ship
@export var circle_radius := 200.0
@export var level_soundtrack : AudioStreamWAV
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var level_duration = $Timer
@onready var spawn_timer = Timer.new()
@onready var circle_enemy_1 : PackedScene = preload("res://scenes/enemy_circle_1.tscn")
# Gescheindikeit für Gegner. Der Wert 5 kom biniert mit einem timer Intervall
# von 5 Sekunden führt dazu dsass die Gegner fats perfekt auf einer Lionie spawnen
@export var winkel_geschwindigkeit : float = 5
@onready var time_delay = 0.8 + GameManager.loop_counter / 5



signal level_finished(next_level_nr: int, gained_score: int, gained_energy: int)



func _ready() -> void:
	player.scale = Vector2(0.2, 0.2)
	level_duration.wait_time = 90 * time_delay
	level_duration.timeout.connect(_on_level_duration_timeout)
	spawn_timer.wait_time = 1 / time_delay
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	spawn_timer.start()
	level_duration.start()
	

	# 2. Circle-Mode aktivieren>
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
func _on_level_duration_timeout():
	GameManager.loop_counter += 1
	emit_signal("level_finished",1, 0, 0)
	
	
func _on_spawn_timer_timeout():
	var new_circle_enemy = circle_enemy_1.instantiate()
	add_child(new_circle_enemy)
