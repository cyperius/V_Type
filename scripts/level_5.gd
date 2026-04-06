extends LevelBase

signal zoom_requested(zoomfactor_x: float, zoomfactor_y: float, zoom_time: float)
signal player_target_activated
signal flight_mode_switch_initiated
signal player_placement_initiated


@onready var voice_audio_stream_player: AudioStreamPlayer = $VoiceAudioStreamPlayer
@onready var zoom_out_timer: Timer = $ZoomOutTimer
@onready var boss_timer: Timer = $BossTimer
@onready var center: Marker2D = $Center
@onready var jason1_damn_it : AudioStreamWAV = load("res://assets/sound_and_sfx/voice_audios/Jason_there_f_everywhere.wav")
@onready var nancy2_initiate_autopilot : AudioStreamWAV = load("res://assets/sound_and_sfx/voice_audios/Nancy_initiate_autopilot.wav")
@onready var nancy3_keep_firing : AudioStreamWAV = load("res://assets/sound_and_sfx/voice_audios/Nancy_keep_firing.wav")
@onready var nancy1_watch_each_others_backs : AudioStreamWAV = load("res://assets/sound_and_sfx/voice_audios/Nancy_watch_each_others_backs.wav")


@export var do_target_player := false

# ----- für circle formation -------- 

@export var circle_radius := 400.0
@export var cirle_shot_scene : PackedScene
@export var winkel_geschwindigkeit : float = 6
@onready var center_node = $Center
var zoom_changing := false
# var player : PlayerShip # falls globaler scope nötig wird -> player._change_flight_state()


# Timeline: Zeitmarken (Sekunden) -> Event-Name
var time_stamps: Dictionary = {
	16.75: "enemies_appear", # 16.75
	64: "zoom_out", # 64.0
	76: "target_player", # ca. 76
	14: "play_radio", 
	#16: "circle_formation" # ca. 96 # Auslösung nach Funkspruch (AudiostreamPlayer)
	
}

var time_stamps_already_triggered: Dictionary = {}
var audio_wiedergabe: AudioStreamPlayback = null


func _ready() -> void:
	super._ready()
	
	audio_wiedergabe = audio_stream_player.get_stream_playback()
	time_stamps_already_triggered.clear()

	# Wichtig: EINMAL verbinden
	if not player_target_activated.is_connected(_on_player_target_activated):
		player_target_activated.connect(_on_player_target_activated)


func _process(delta: float) -> void:
	if not audio_stream_player.playing:
		return
	if audio_wiedergabe == null:
		return
	print("centerNode position: ", center_node.global_position)
	if zoom_changing: # die verwendete Methode in CameraUtils (class_name CameraUtils) ist als "static func" definiert
		# das bedeutedie kann direkt auf die Klasse CameraUtils verwendet werden, ohne Instanz
		center.global_position = CameraUtils.get_center_world_coordinates(get_viewport())
	
	var aktuelle_audio_zeit: float = audio_wiedergabe.get_playback_position()

	for time_stamp in time_stamps.keys():
		if aktuelle_audio_zeit >= time_stamp and not time_stamps_already_triggered.get(time_stamp, false):
			var event_name: String = time_stamps[time_stamp]
			loese_audio_ereignis_aus(event_name)
			time_stamps_already_triggered[time_stamp] = true


func _place_all_players_in_circle_formation() -> void:
	for player_id in Global.player_ships.keys():
		var player := Global.get_player_ship(player_id)
		if player is PlayerShip:
			player._change_flight_state()
			prepare_player_for_circle_formation(player, player_id)
			
			# print(" (level_base.gd): nr of players : ", player_id)



func prepare_player_for_circle_formation(player: PlayerShip, player_id: int) -> void:
	# Level 3: Spieler auf Kreisbahn spawnen (Circle-Mode)
	
	#player.hide() # 21.2.26: spieler blitz trotzdem am Anfang kurz auf..
	
	# 0) Signale zum Player verbinden
	player.connect_signals()
	# evtl. beim player noch ein signal anfügen
	
	# 1) Modus aktivieren
	player.mode = player.FlightMode.CIRCLE

	# 2) Kreis-Parameter setzen  # (erst mit Zugriff auf player.global_positiion 
	# wird der Spieler dann wirklich an die Stelle versetzt)
	player.circle_center_position = center_node.global_position
	player.circle_radius = circle_radius


	# 3) Startwinkel (gleichmäßig nach aktueller Spieleranzahl)
	var active_count : int = max(1, Global.player_ships.size())
	var start_angle: float = 2.0 * PI * float(player_id - 1) / float(active_count)
	player.angle = start_angle + 2 * PI
	player.face_circle_center = false
	
	
	# Zielposition für Autopiloten berechnen:
	var autopilot_target_position = player.circle_center_position + Vector2(cos(start_angle), sin(start_angle)) * player.circle_radius
	var autopilot_target_rotation = center_node.global_position.angle_to_point(autopilot_target_position) # Winkel vom Mittelpunkt zur Zielposition auf dm Kreis
	# Dann per Methodenaufruf im playerAutoPilotModul übermitteln, und Autopilot aktivieren
	player.auto_pilot_modul._set_new_target_destination(autopilot_target_position, autopilot_target_rotation, true)
	print("player ", player_id, "level5: player_roatation= ", center_node.global_position.angle_to_point(autopilot_target_position))
	

	# 4) Optional: Level-spezifische Skalierung (rein visuell)
	player.scale = Vector2(0.2, 0.2)


#await # Animationsende
## ---- Animationsende von player_ship abwarten dann: --
#
	await get_tree().process_frame  # warte bis hide() gerendert wurde
	# 5) Level-spezifische skin und Ausrichtung setzen
	player.set_skin("top_down")
	player.show()
	
	
	## 7) Signal senden um stats im Flightmodulk des Players zu aktualisieren
	#player_placement_initiated.emit()
#
	## 8) Debug
	#print("🌀 Spieler %d im Circle-Mode @ %s (r=%.1f, angle=%.2f)" % [
		#player_id, player.circle_center_position, player.circle_radius, start_angle
	#])


func loese_audio_ereignis_aus(event_name: String) -> void:
	match event_name:
		"enemies_appear":
			enemies_appear()
		"zoom_out":
			zoom_out(0.5 * zoom_factor.x, 0.5 * zoom_factor.y, 34.0)
			zoom_changing = true
			# Signal ans palyer_schiff, das das spride versteckt wird und das
			# animatedsprite abgespeilt wird, und evtl. Steuerung aufheben / Autolenkung
			# Zusammenspiel mit AutopilotModul?
		"target_player":
			start_attacking_player()
		"play_radio":
			play_radio()
		"circle_formation":
			_place_all_players_in_circle_formation()
			
		_:
			push_warning("Unbekanntes Timeline-Event: %s" % event_name)

	
func enemies_appear() -> void:
	enemy_spawner.set_spawn_rate(5) # 5


func zoom_out(x_factor: float, y_factor: float, zoom_time: float) -> void:
	emit_signal("zoom_requested", x_factor, y_factor, zoom_time)


func start_attacking_player() -> void:
	emit_signal("player_target_activated")

func play_radio() -> void:
	voice_audio_stream_player.stream = jason1_damn_it
	voice_audio_stream_player.play()
	
	await  voice_audio_stream_player.finished
	voice_audio_stream_player.stream = nancy1_watch_each_others_backs
	voice_audio_stream_player.play()

	await  voice_audio_stream_player.finished
	voice_audio_stream_player.stream = nancy2_initiate_autopilot
	voice_audio_stream_player.play()
	

	await  voice_audio_stream_player.finished
	voice_audio_stream_player.stream = nancy3_keep_firing
	voice_audio_stream_player.play()
	await get_tree().create_timer(0.8).timeout
	loese_audio_ereignis_aus("circle_formation")

func _on_player_target_activated() -> void:
	print("level5.gd: on_player_target reached")
	do_target_player = true


func _on_incoming_boss() -> void:
	audio_stream_player.stop()
