extends Node2D

signal finished

@export var sfx_stream: AudioStream
var explosion: PackedScene = load("res://scenes/explosion_animation.tscn")

@onready var audio_stream_player = $AudioStreamPlayer
@onready var main = $".."


func _ready() -> void:
	print("ausgelöst")
	if Global.destroyed_player_ships != []:
		var destroyed_player = Global.destroyed_player_ships.back()
		self.global_position = destroyed_player.global_position
		print("Initialposition: ", self.global_position)
	else:
		print("kein Spieler im destroyed_player Dictionary")
	add_child(explosion.instantiate())
	if Global.destroyed_player_ships.size() == Global.player_ships.size():
		reset_level()
	
	
func reset_level():
	audio_stream_player.play()
	await audio_stream_player.finished
	emit_signal("finished")
		
