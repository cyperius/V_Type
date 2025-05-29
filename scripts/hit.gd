extends Node2D

@onready var mini_explosion = $explosion_animation
@onready var audio_stream_player_2d: AudioStreamPlayer = $AudioStreamPlayer2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mini_explosion.play()
	audio_stream_player_2d.play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
