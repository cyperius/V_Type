extends Node2D  # MainScene basiert auf Node2D

signal level_finished(next_level_nr: int, gained_score: int, gained_energy: int)
signal enemy_destroyed(score: int, energy: int, player_id: int)
signal zoom_requested(zoomfactor_x: float, zoomfactor_y : float, zoom_time: int)

@onready var audio_player = $AudioStreamPlayer
@onready var boss_timer = $BossTimer
@onready var enemy_spawner = $EnemySpawner
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
	# Levelstart: Zerstörte IDs zurücksetzen
	Global.reset_round_state()
	# Alle registrierten Spieler ins Level setzen
	_place_all_players_in_current_level()

	# ── Global Signale
	#das Global.roster_changed Signal feuert, wenn die Anz. Spieler geändert hat
	# wenn dies der Fall, werden gewisse Level Pramter angepasst -> func _on_number...
	Global.roster_changed.connect(_on_number_of_players_changed)
		# Playback-Objekt holen
	audio_wiedergabe = audio_player.get_stream_playback()

	# Sicherstellen, dass wir frisch beginnen
	time_stamps_already_triggered.clear()
	
	# alte Signalschreibweise
	enemy_spawner.connect("boss_defeated", Callable(self, "_on_boss_defeated")) # Cannot call method 'connect' on a null value.
	# neue Signalschreibweise (seit Godot 4.2 werden Signale als Obkete behandelt, daher so schreibbar)
	enemy_spawner.enemy_spawned.connect(_on_enemy_spawned)
	enemy_spawner.incoming_boss.connect(_on_incoming_boss)
	# neu:  🔁 Für alle registrierten Spieler im Global-Singleton
	for player_id in Global.player_ships.keys():
		var player = Global.get_player_ship(player_id)
		player.mode = player.FlightMode.LEFT_RIGHT
		player.rotation_degrees = 0
		#player.collision_mask = (1 << 2) | (1 << 3) | (1 << 4) | (1 << 5)
		#player.collision_layer = 1
		player.global_position = Vector2 (500, 1000 + 200 * player_id)
		player.scale = Vector2(0.25, 0.25)
	#Global.player_ship.speed = Global.player_ship.max_speed
		player.show()
	
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

	
func _on_enemy_destroyed(score: int, energy: int, player_id) -> void:
	emit_signal("enemy_destroyed", score, energy, player_id)
	
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
	
func _place_all_players_in_current_level() -> void:
	for player_id in Global.player_ships.keys():
		var player := Global.get_player_ship(player_id)
		if player is PlayerShip:
			place_player_in_current_level(player, player_id)


func place_player_in_current_level(player: PlayerShip, player_id: int) -> void:
	# Level 5: Standard-LEFT_RIGHT-Mode, Spawn in Viewport-Mitte + Offset

	# 1) Grundzustände
	player.mode = player.FlightMode.LEFT_RIGHT
	player.rotation_degrees = 0
	player.collision_mask = (1 << 2) | (1 << 3) | (1 << 4) | (1 << 5)
	player.collision_layer = 1

	# 2) Positionierung wie in Main: Mitte + je Spieler versetzter Offset
	var viewport_size: Vector2 = get_viewport_rect().size
	var base_position = viewport_size * 0.05
	var player_offset = Vector2(180, 60 + 240 * (player_id - 1))
	player.global_position = base_position + player_offset

	# 3) Einheitliche Skalierung für Level 5
	player.scale = Vector2(0.25, 0.25)

	# 4) Sichtbar schalten
	player.show()


# Der frisch gespawnte Gegner wird übergeben → wir verbinden sein Signal
func _on_enemy_spawned(enemy: Node) -> void:
	# ✳️ Idealfall: Der Enemy sendet bereits (score, energy, player_id).
	if enemy.has_signal("enemy_destroyed"):
		print("level5: enemy_spawned and connected enemy_destroyed signal")
		# Direkte 1:1‑Weiterleitung
		enemy.enemy_destroyed.connect(func(score: int, energy: int, player_id: int) -> void:
			emit_signal("enemy_destroyed", score, energy, player_id))
			
	else:
		print("⚠️ Enemy hat kein 'enemy_destroyed'-Signal.")
		

func _on_number_of_players_changed() -> void:
	enemy_spawner.set_spawn_rate()
