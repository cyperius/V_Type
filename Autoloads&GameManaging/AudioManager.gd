extends Node
# Dieses Script ist als Autoload/Singleton gedacht, damit du es von überall aufrufen kannst.
# (Project Settings > Autoload > AudioManager.gd hinzufügen)

class_name AudioManagerClass
# class_name erlaubt dir, AudioManager überall direkt zu referenzieren,
# selbst wenn du den Autoload-Namen mal ändern würdest.

# ──────────────────────────────────────────────────────────────
# KONFIGURATION / KONSTANTEN
# ──────────────────────────────────────────────────────────────

const DEFAULT_SFX_BUS_NAME: String = "SFX"
# Standard-Bus, auf dem SFX abgespielt werden sollen.
# Wichtig: Dieser Bus muss im Audio-Bus-Layout existieren, sonst fällt Godot auf "Master" zurück bzw. macht unerwartete Dinge.

@export var sfx_pool_size: int = 24
# Anzahl AudioStreamPlayer, die wir für Soundeffekte im Pool erstellen.
# Je höher dieser Wert, desto mehr SFX können gleichzeitig überlappen (Polyphonie),
# aber desto mehr Nodes hat dein AudioManager in der Szene.

@export var sfx_bus_name: String = DEFAULT_SFX_BUS_NAME
# In den Inspector exportiert, damit du den Busnamen ändern kannst, ohne im Code anzufassen.
# Beispiel: "SFX_Weapons" oder "SFX" (je nach deinem Bus-Setup).

# ──────────────────────────────────────────────────────────────
# NODE-REFERENZEN (AUS DER SZENE)
# ──────────────────────────────────────────────────────────────

@onready var music_player: AudioStreamPlayer = $MusicPlayer
# Greift beim Laden der Szene auf den Child-Node "MusicPlayer" zu.
# Dieser Player ist für Hintergrundmusik gedacht (meist nur 1 Stream gleichzeitig).

# ──────────────────────────────────────────────────────────────
# DATEN (DICTIONARIES) FÜR SOUNDS / MUSIK
# ──────────────────────────────────────────────────────────────

var sounds: Dictionary = {}
# Dictionary für Soundeffekte: Key = Name (String), Value = AudioStream (preload)
# Beispiel: sounds["laser_shot"] -> AudioStream

var music_tracks: Dictionary = {}
# Dictionary für Musiktracks: Key = Name (String), Value = AudioStream
# Du kannst später pro Level Tracks hier reinlegen, oder dynamisch befüllen.

# ──────────────────────────────────────────────────────────────
# SFX-POOL (POLYPHONIE)
# ──────────────────────────────────────────────────────────────

var sfx_players: Array[AudioStreamPlayer] = []
# Hier speichern wir die erstellten AudioStreamPlayer (Pool).

var next_sfx_player_index: int = 0
# Zeigt auf den nächsten Player im Pool (Round-Robin).
# Round-Robin bedeutet: wir nehmen reihum den nächsten Player, um Sounds zu starten.

# ──────────────────────────────────────────────────────────────
# LIFECYCLE
# ──────────────────────────────────────────────────────────────

func _ready() -> void:
	# _ready() wird von Godot automatisch aufgerufen, sobald die Node im SceneTree ist.
	# Hier initialisieren wir alles, was beim Start bereit sein soll.

	_create_sfx_pool()
	# Erstellt sfx_pool_size viele AudioStreamPlayer und hängt sie an den AudioManager.

	# --- Soundeffekte in Dictionary laden ---
	# preload() lädt die Ressource direkt beim Start (schnell, sicher, keine Laufzeit-Lags).
	# Der Pfad muss exakt stimmen, sonst gibt es beim Start eine Fehlermeldung.
	sounds["laser_shot"] = preload("res://assets/sound_and_sfx/sound_effects/laser_shot.wav")
	sounds["laser_blast"] = preload("res://assets/sound_and_sfx/sound_effects/laser_blast.wav")
	sounds["explosion"] = preload("res://assets/sound_and_sfx/sound_effects/explosion_lang_sanft.wav")
	sounds["intense_laser"] = preload("res://assets/sound_and_sfx/sound_effects/intense_Laser.wav")

	# Hinweis: music_tracks füllst du später je nach Projektstruktur (pro Level / global).
	# Beispiel:
	# music_tracks["level_1"] = preload("res://assets/music/level_1.ogg")

# ──────────────────────────────────────────────────────────────
# SFX-POOL ERZEUGEN
# ──────────────────────────────────────────────────────────────

func _create_sfx_pool() -> void:
	# Erzeugt mehrere AudioStreamPlayer, damit viele SFX gleichzeitig abgespielt werden können.

	# Sicherheit: falls _create_sfx_pool mal doppelt aufgerufen wird, leeren wir den Pool vorher.
	# (Normalerweise passiert das nicht, aber es ist ein guter Schutz gegen doppelte Initialisierung.)
	for old_player in sfx_players:
		if is_instance_valid(old_player):
			old_player.queue_free()
	sfx_players.clear()

	# Wir erzeugen sfx_pool_size Player.
	for i in sfx_pool_size:
		# Neuen AudioStreamPlayer Node erzeugen (nicht 2D/3D, sondern "globaler" Player).
		# Für positional Audio (2D) würden wir AudioStreamPlayer2D verwenden (können wir später ergänzen).
		var player := AudioStreamPlayer.new()

		# Den Bus setzen, damit SFX getrennt von Musik gemischt und geregelt werden können.
		player.bus = sfx_bus_name

		# Player dem SceneTree hinzufügen, damit er überhaupt abspielen kann.
		add_child(player)

		# In unserem Array speichern, damit wir ihn später wiederfinden/benutzen.
		sfx_players.append(player)

	# Index zurücksetzen, damit Round-Robin sauber bei 0 beginnt.
	next_sfx_player_index = 0

# ──────────────────────────────────────────────────────────────
# MUSIK-FUNKTIONEN
# ──────────────────────────────────────────────────────────────

func play_music(track_name: String, volume: float = 1.0) -> void:
	# Spielt einen Musiktrack ab, der im Dictionary music_tracks hinterlegt ist.

	# Prüfen, ob der Key im Dictionary vorhanden ist.
	if track_name in music_tracks:
		# Stream (Audio-Datei) setzen.
		music_player.stream = music_tracks[track_name]

		# Lautstärke setzen. volume kommt als "linear" (0..1), wir rechnen in dB um.
		music_player.volume_db = linear_to_db(volume)

		# Musik starten.
		music_player.play()
	else:
		# Debug-Ausgabe, falls Track nicht existiert.
		print("Fehler: Musiktrack '" + track_name + "' nicht gefunden!")


func stop_music() -> void:
	# Stoppt die Musik sofort.
	music_player.stop()


func fade_out_music(duration: float = 2.0) -> void:
	# Blendet die Musik über duration Sekunden aus, indem volume_db Richtung -80 dB animiert wird.
	# -80 dB ist praktisch "stumm".

	var tween := create_tween()
	# Tween erstellt eine zeitbasierte Animation.

	tween.tween_property(music_player, "volume_db", -80.0, duration).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	# tween_property: verändert eine Property eines Objekts (hier music_player.volume_db)
	# von aktuellem Wert -> -80.0 über duration Sekunden.

# ──────────────────────────────────────────────────────────────
# SFX-FUNKTIONEN (POLYPHON)
# ──────────────────────────────────────────────────────────────

func play_sfx_string(sound_name: String, volume: float = 1.0, pitch_scale: float = 1.0) -> void:
	# Spielt einen SFX anhand eines Namens ab, der im sounds-Dictionary existiert.

	# Prüfen, ob der Sound vorhanden ist.
	if sounds.has(sound_name):
		# Wenn vorhanden, rufen wir die Stream-Variante auf.
		play_sfx(sounds[sound_name], volume, pitch_scale)
	else:
		# Debug-Ausgabe, falls Sound nicht gefunden wurde.
		print("⚠ Fehler: Sound '%s' nicht gefunden!" % sound_name)


func play_sfx(audio_stream: AudioStream, volume: float = 1.0, pitch_scale: float = 1.0) -> void:
	# Spielt einen Soundeffekt ab (polyphon), indem ein Player aus dem Pool verwendet wird.

	# Wenn kein Stream übergeben wurde, können wir nichts abspielen.
	if audio_stream == null:
		return

	# Wenn der Pool leer ist (sollte nicht passieren, aber Sicherheit), abbrechen.
	if sfx_players.is_empty():
		return

	# Nächsten Player aus dem Pool holen (Round-Robin).
	var player := sfx_players[next_sfx_player_index]

	# Index erhöhen und am Ende wieder auf 0 springen (Modulo).
	next_sfx_player_index = (next_sfx_player_index + 1) % sfx_players.size()

	# Stream setzen (welche Audio-Datei abgespielt werden soll).
	player.stream = audio_stream

	# Lautstärke setzen (linear 0..1 -> dB).
	player.volume_db = linear_to_db(volume)

	# Pitch setzen (1.0 = normal, >1 höher, <1 tiefer).
	# Das ist nützlich, um leichte Variation reinzubringen (z.B. random 0.95..1.05).
	player.pitch_scale = pitch_scale

	# Wichtig: Player stoppen, falls er gerade noch etwas abspielt.
	# Dadurch erzwingen wir einen sauberen Neustart auf diesem Player.
	# (Bei Round-Robin kann es sein, dass der Player noch läuft, wenn der Pool zu klein ist.)
	player.stop()

	# Sound starten.
	player.play()

# ──────────────────────────────────────────────────────────────
# HELFERFUNKTIONEN
# ──────────────────────────────────────────────────────────────

func linear_to_db(volume: float) -> float:
	# Wandelt lineare Lautstärke (0..1) in dB um.
	# 1.0 -> 0 dB
	# 0.5 -> ca. -6 dB
	# 0.0 -> -80 dB (praktisch stumm)

	if volume <= 0.0:
		return -80.0

	# dB = 20 * log10(volume)
	# In GDScript nutzen wir log(x) und teilen durch log(10) um log10 zu bekommen.
	return 20.0 * (log(volume) / log(10.0))
