extends Node2D

signal finished

@export var sfx_stream: AudioStream
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

## Schutzflag: verhindert Mehrfachauslösung (z.B. bei schnellen mehrfachen Signal-Events)
var game_over_already_triggered: bool = false

func _ready() -> void:
	# Auf alle relevanten Global-Änderungen hören:
	# - Spieler beitreten/verlassen
	# - Spieler zerstört/belebt
	Global.player_registered.connect(_on_roster_changed)
	Global.player_unregistered.connect(_on_roster_changed)
	Global.player_destroyed.connect(_on_roster_changed)
	Global.player_revived.connect(_on_roster_changed)
	Global.roster_changed.connect(_on_roster_changed) # generelles Fallback

	# Falls die Szene geladen wird, nachdem bereits alle zerstört wurden:
	_check_for_game_over()

func _on_roster_changed(_player_id := -1) -> void:
	_check_for_game_over()

func _check_for_game_over() -> void:
	if game_over_already_triggered:
		return

	# Zentrale, ID-basierte Bedingung abfragen
	if Global.should_game_over():
		game_over_already_triggered = true
		reset_level()

func reset_level() -> void:
	# Sound abspielen (falls gesetzt), dann „finished“-Signal emittieren.
	if sfx_stream != null:
		audio_stream_player.stream = sfx_stream
	audio_stream_player.play()
	await audio_stream_player.finished
	emit_signal("finished")
