extends Node2D

signal finished

@export var sfx_stream: AudioStream
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

func _ready() -> void:
	# NUR Sound abspielen, dann finished senden
	if sfx_stream != null:
		audio_stream_player.stream = sfx_stream

	_play_and_finish()


func _play_and_finish() -> void:
	audio_stream_player.play()
	await audio_stream_player.finished
	emit_signal("finished")
