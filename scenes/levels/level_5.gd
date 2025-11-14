extends Node2D  # MainScene basiert auf Node2D

signal level_finished(next_level_nr: int, gained_score: int, gained_energy: int)
signal enemy_destroyed(score: int, energy: int)
signal zoom_requested(zoomfactor_x: float, zoomfactor_y : float, zoom_time: int)

@onready var audio_player = $AudioStreamPlayer
@onready var boss_timer = $BossTimer
@onready var enemy_spawner: EnemySpawner = $EnemySpawner
@export var amount_of_enemies : int
@onready var enemies_container : Node2D = $EnemiesContainer
@onready var zoom_out_timer: Timer = $ZoomOutTimer


# Liste von Zeitmarken (in Sekunden)
var time_stamps: Dictionary = {
	16.75: "enemies_appear",
	64.00: "zoom_out",
	
}

# Damit jede Zeitmarke nur einmal ausgelöst wird
var time_stamps_already_triggered: Dictionary = {}

# Referenz auf das Playback-Objekt für genaue Zeitmessung
var audio_wiedergabe: AudioStreamPlayback = null

func _ready():
		# Playback-Objekt holen
	audio_wiedergabe = audio_player.get_stream_playback()

	# Sicherstellen, dass wir frisch beginnen
	time_stamps_already_triggered.clear()
	
	var enemy = preload("res://scenes/enemy_4.tscn").instantiate()
	# alte Signalschreibweise
	enemy_spawner.connect("boss_defeated", Callable(self, "_on_boss_defeated")) # Cannot call method 'connect' on a null value.
	# neue Signalschreibweise (seit Godot 4.2 werden Signale als Obkete behandelt, daher so schreibbar)
	enemy_spawner.enemy_spawned.connect(_on_enemy_spawned)
	enemy_spawner.incoming_boss.connect(_on_incoming_boss)
	# neu:  🔁 Für alle registrierten Spieler im Global-Singleton
	for player_id in Global.player_ships.keys():
		var player = Global.get_player_ship(player_id)
		player.mode = player.PlayerMode.FREE
		player.rotation_degrees = 0
		#player.collision_mask = (1 << 2) | (1 << 3) | (1 << 4) | (1 << 5)
		#player.collision_layer = 1
		player.global_position = Vector2 (500, 1000 + 200 * player_id)
		player.scale = Vector2(0.25, 0.25)
	#Global.player_ship.speed = Global.player_ship.max_speed
		player.show()
	enemies_container.add_child(enemy)
	#falls Boss zu fixer Zeit gespawnt werden soll reaktivieren:
	#boss_timer.wait_time = 100 # kann im Editor überschrieben werden
	#boss_timer.timeout.connect(_on_boss_timer_timeout)
	
	
	#background.size = Vector2(3840, 2880)  # Falls FullHD-Fenstergröße
	#background.position = Vector2(-1920, -1440)  # Stelle sicher, dass er oben links beginnt

# Der "Trick" Der frisch gespawnte "enemy" wird als Node übergeben. So kann auf dessen Signal
# "enemy_destroyed" zugegriffen werden


func _process(delta: float) -> void:
	if audio_player.playing and audio_wiedergabe:
		var aktuelle_audio_zeit: float = audio_wiedergabe.get_playback_position()

		# Alle Zeitmarken durchgehen
		for time_stamp in time_stamps.keys():
			if aktuelle_audio_zeit >= time_stamp and not time_stamps_already_triggered.get(time_stamp, false):
				var event_name : String = time_stamps[time_stamp]
				loese_audio_ereignis_aus(event_name)
				time_stamps_already_triggered[time_stamp] = true


func loese_audio_ereignis_aus(method_to_call: String) -> void:
	match method_to_call:
		"enemies_appear":
			enemies_appear()
			print("enemies!!!!")
		"zoom_out":
			zoom_out(0.5, 0.5, 34)


func _on_enemy_spawned(enemy: Node) -> void:
	enemy.enemy_destroyed.connect(_on_enemy_destroyed)
	
	
func _on_enemy_destroyed(score: int, energy: int) -> void:
	emit_signal("enemy_destroyed", score, energy)
	
func _on_boss_timer_timeout():
	pass
	
	
func _on_boss_defeated():
	GameManager.loop_counter += 1
	emit_signal("level_finished", 1, 0, 0) 
	print("boss defeated")
	
func _on_incoming_boss() -> void:
	audio_player.stop()


func zoom_out(x_faxtor : float, y_factor : float, zoom_time: int) -> void:
	emit_signal("zoom_requested", x_faxtor, y_factor, zoom_time)
	print("zoom_requested signal emitted")
	

func enemies_appear():
	print("enemies_appear_function_activated")
	enemy_spawner.set_spawn_rate(5)
	
