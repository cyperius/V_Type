extends Node2D

@export var sfx_stream: AudioStream
var explosion: PackedScene = load("res://scenes/explosion_animation.tscn")

@onready var audio_stream_player = $AudioStreamPlayer
@onready var main = $".."


func _ready() -> void:
	print("ausgelöst")
	if Global.player_ship:
		# Hier greifst du auf eine Eigenschaft des Player-Schiffs zu,
		# z. B. auf einen Kind-Knoten 'ship_sprite'
		self.position = Global.player_sprite.global_position
		print("Initialposition: ", self.position)
	else:
		print("Global.player_ship ist nicht gesetzt!")
	add_child(explosion.instantiate())
	reset_level()
	
	
func reset_level():
	audio_stream_player.play()
	await audio_stream_player.finished
	GameManager._load_level(GameManager.current_level)
		
