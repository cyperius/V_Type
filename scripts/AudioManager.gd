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
	
	music_tracks["ambush_16bit"] = preload("res://assets/sound_and_sfx/soundtracks/survival_mode/fight.wav")
	music_tracks["level_1"] = preload("res://assets/sound_and_sfx/soundtracks/Level_sountracks/no_stars.wav")
	music_tracks["level_2"] = preload("res://assets/sound_and_sfx/soundtracks/Level_sountracks/Hero Immortal.wav")
	music_tracks["level_3"] = preload("res://assets/sound_and_sfx/soundtracks/Level_sountracks/through_space.wav")
	music_tracks["level_4"] = preload("res://assets/sound_and_sfx/soundtracks/Level_sountracks/Label 03 somewhere Mid Level.wav")
	music_tracks["level_5"] = preload("res://assets/sound_and_sfx/soundtracks/Level_sountracks/Label_ist gut_Mid_Levelish.wav")
	music_tracks["level_6"] = preload("res://assets/sound_and_sfx/soundtracks/Level_sountracks/Not Alone.wav")
	music_tracks["level_7"] = preload("res://assets/sound_and_sfx/soundtracks/Level_sountracks/Label - “the heroes are coming” sehr heroisch, ohne Bedrohung.wav")
	music_tracks["path_to_boss"]  = preload("res://assets/sound_and_sfx/soundtracks/boss_Themes/Label_ could be intense way to ultimate Final Boss Battle.wav")
	music_tracks["boss_1"] = preload("res://assets/sound_and_sfx/soundtracks/boss_Themes/Label _ earlyStage_Boss.wav")
	music_tracks["boss_2"] = preload("res://assets/sound_and_sfx/soundtracks/boss_Themes/Label_another_good_Boss_music.wav")
	music_tracks["final_boss"] = preload("res://assets/sound_and_sfx/soundtracks/boss_Themes/Label_Cracy Bossfight.wav")
	music_tracks["survival_1"] = preload("res://assets/sound_and_sfx/soundtracks/survival_mode/Label Survival Mode.wav")
	music_tracks["survival_2"] = preload("res://assets/sound_and_sfx/soundtracks/survival_mode/Label Survival or adhs Boss.wav")
	music_tracks["survival_3"] = preload("res://assets/sound_and_sfx/soundtracks/survival_mode/Label Umbush (from all sides mode_).wav")


func play_music(track_name: String, volume: float = 1.0) -> void:
	if track_name in music_tracks:
		music_player.stream = music_tracks[track_name]
		music_player.play()
		music_player.volume_db = linear2db(volume)
	else:
		print("Fehler: Musiktrack '" + track_name + "' nicht gefunden!")


func stop_music() -> void:
	music_player.stop()

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
	

