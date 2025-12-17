extends LevelBase

signal zoom_requested(zoomfactor_x: float, zoomfactor_y: float, zoom_time: float)
signal player_target_activated

@onready var zoom_out_timer: Timer = $ZoomOutTimer
@onready var boss_timer: Timer = $BossTimer

@export var do_target_player := false

# Timeline: Zeitmarken (Sekunden) -> Event-Name
var time_stamps: Dictionary = {
	2: "enemies_appear", # 16.75
	64.0: "zoom_out",
	10: "target_player", # ca. 76
}

var time_stamps_already_triggered: Dictionary = {}
var audio_wiedergabe: AudioStreamPlayback = null


func _ready() -> void:

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

	var aktuelle_audio_zeit: float = audio_wiedergabe.get_playback_position()

	for time_stamp in time_stamps.keys():
		if aktuelle_audio_zeit >= time_stamp and not time_stamps_already_triggered.get(time_stamp, false):
			var event_name: String = time_stamps[time_stamp]
			loese_audio_ereignis_aus(event_name)
			time_stamps_already_triggered[time_stamp] = true


func loese_audio_ereignis_aus(event_name: String) -> void:
	match event_name:
		"enemies_appear":
			enemies_appear()
		"zoom_out":
			zoom_out(0.5, 0.5, 34.0)
		"target_player":
			start_attacking_player()
		_:
			push_warning("Unbekanntes Timeline-Event: %s" % event_name)

	
func enemies_appear() -> void:
	enemy_spawner.set_spawn_rate(5)


func zoom_out(x_factor: float, y_factor: float, zoom_time: float) -> void:
	emit_signal("zoom_requested", x_factor, y_factor, zoom_time)


func start_attacking_player() -> void:
	emit_signal("player_target_activated")


func _on_player_target_activated() -> void:
	print("level5.gd: on_player_target reached")
	do_target_player = true


func _on_incoming_boss() -> void:
	audio_stream_player.stop()
