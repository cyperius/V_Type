extends AnimatedSprite2D

@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

func _ready() -> void:
	play()
	animation_finished.connect(_on_animation_finished)
	audio_stream_player_2d.play()
	
	
func _on_animation_finished() -> void:
	queue_free()
