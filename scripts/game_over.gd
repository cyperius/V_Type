extends Node2D

signal finished

@export var sfx_stream: AudioStream

@onready var audio_stream_player = $AudioStreamPlayer
@onready var main = $".."


func _ready() -> void:
	print("ausgelöst")
	if Global.destroyed_player_ships.size() == Global.player_ships.size():
		reset_level()
	
	
func reset_level():
	audio_stream_player.play()
	await audio_stream_player.finished
	emit_signal("finished")
		
