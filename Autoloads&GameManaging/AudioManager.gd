extends Node

@onready var music_player = $MusicPlayer
@onready var sfx_player = $SfxPlayer

var sounds = {}
var music_tracks = {}

func _ready() -> void:
	set_process(true)
	sounds["laser_shot"] = preload("res://assets/sound_and_sfx/sound_effects/laser_shot.wav")
	sounds["laser_blast"] = preload("res://assets/sound_and_sfx/sound_effects/laser_blast.wav")
	sounds["explosion"] = preload("res://assets/sound_and_sfx/sound_effects/explosion_lang_sanft.wav")
	sounds["intense_laser"] = preload("res://assets/sound_and_sfx/sound_effects/intense_Laser.wav")
	

func play_music(track_name: String, volume: float = 1.0) -> void:
	if track_name in music_tracks:
		music_player.stream = music_tracks[track_name]
		music_player.play()
		music_player.volume_db = linear2db(volume)
	else:
		print("Fehler: Musiktrack '" + track_name + "' nicht gefunden!")


func stop_music() -> void:
	music_player.stop()

 # -- Variante via Stream Namen (siehe oben sounds-Dictionary-- #
func play_sfx_string(sound_name: String, volume: float = 1.0) -> void:
	if sounds.has(sound_name):  # Prüft, ob der Sound existiert
		sfx_player.stream = sounds[sound_name]
		sfx_player.volume_db = linear2db(volume)
		sfx_player.play()
	else:
		print("⚠ Fehler: Sound '%s' nicht gefunden!" % sound_name)
		
		
func play_sfx(sound_name: AudioStream, volume: float = 1.0) -> void:
	sfx_player.volume_db = linear2db(volume)
	sfx_player.stream = sound_name
	sfx_player.play()
	

func linear2db(volume: float) -> float:
	if volume <= 0:
		return -80
	return 20 * (log(volume) / log(10))
	

func fade_out(duration : float = 2.0):
	var tween := create_tween()
	tween.tween_property(music_player, "volume_db", -80, duration).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	
