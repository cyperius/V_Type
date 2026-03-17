extends LevelBase

signal end_phase1
signal end_phase2

@onready var timer: Timer = $EnemySpawner/Timer
@onready var timer_2: Timer = $EnemySpawner/Timer2



# Timeline: Zeitmarken (Sekunden) -> Event-Name
var time_stamps: Dictionary = {
	96.5: "phase_2_intense", # timestamp: 96.5 / 92.3
	115.2: "phase_3_more_intense", # timestamp 115.2
	120.5: "phase_4_relax_a_bit", # 120.5
	154: "phase_5_intense_again", #154
	192: "phase_6_relax_again", # 192
	212: "phase_7_ending", # 212,
	12: "here_comes_the_boss", # 272
}

var time_stamps_already_triggered: Dictionary = {}
var audio_wiedergabe: AudioStreamPlayback = null

var phase_2_activated := false
var phase_1_activated := true


func _ready() -> void:
	super._ready()
	
	audio_wiedergabe = audio_stream_player.get_stream_playback()
	time_stamps_already_triggered.clear()


func _process(delta: float) -> void:
	if not audio_stream_player.playing:
		return
	if audio_wiedergabe == null:
		return

	var aktuelle_audio_zeit: float = audio_wiedergabe.get_playback_position()

	for time_stamp in time_stamps.keys(): # folgende 2 Zeilen: äussere Klammer dient nur Zeilenumbruch
		if (aktuelle_audio_zeit >= time_stamp # Bedingung 1
				and not time_stamps_already_triggered.get(time_stamp, false)): #Bedingung 2
			
		# Bedingung 1: Die aktuelle Audiozeit hat den Zeitstempel erreicht oder überschritten.
		# Bedingung 2: Dieser Zeitstempel wurde noch nicht ausgelöst.
		# get(time_stamp, false) bedeutet:
			# - Wenn der time_stamp schon im Dictionary existiert, wird dessen Wert zurückgegeben (diesen
			# Wert setzen wir unten auf "true")
			# - Wenn der key noch nicht existiert, wird false zurückgegeben.
		# Durch das "not" wird daraus beim ersten Mal "true", also darf das Ereignis ausgelöst werden.
		# Danach setzen wir den Eintrag auf "true",
		# sodass dieselbe Stelle später nicht noch einmal ausgelöst wird.
			var event_name: String = time_stamps[time_stamp] # time_stamps ist der Dictionary und 
			# [time_stamp] der key: ein float Wert, der für Sekunden steht, wenn die aktuell verstrichene Audiozeit
			# diesen Wert überschreitet, wird der zugehörige Audio-Ereignis ausgelöst, indem 
			# loese_audio_ereignis_aus(event_name) ausgelöst wird
			loese_audio_ereignis_aus(event_name)
			time_stamps_already_triggered[time_stamp] = true # damit kann da sEreignis kein 2. mal ausgelöst werden


func loese_audio_ereignis_aus(event_name: String) -> void:
	match event_name:
		"phase_2_intense":
			enemy_spawner.timer3.start(3)
		"phase_3_more_intense":
			phase_2_activated = true
		"phase_4_relax_a_bit":
			emit_signal("end_phase2")
			enemy_spawner.timer3.paused = true
			timer.start(3) # starten und wait_time festsetzen in einem ;-)
		"phase_5_intense_again":
			enemy_spawner.timer3.paused = false
			timer_2.start(3)
			phase_2_activated = true
		"phase_6_relax_again":
			emit_signal("end_phase2")
			enemy_spawner.timer3.paused = true
			timer_2.paused = true
		"phase_7_ending":
			emit_signal("end_phase1")
			timer.wait_time = 1
			timer_2.paused = false
			timer_2.wait_time = 1.5
			enemy_spawner.timer3.paused = false
			enemy_spawner.timer3.wait_time = 2
		"here_comes_the_boss":
			"is boss coming?"
			enemy_spawner.here_comes_the_boss()
			
		_:
			push_warning("Unbekanntes Timeline-Event: %s" % event_name)
