extends AnimatedSprite2D


@onready var audio_stream_player_2d = $AudioStreamPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animation_finished.connect(_on_animation_finished)
	play()
	audio_stream_player_2d.play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_animation_finished() -> void:
	#print("Schluss mit der Animation")
	pass
	queue_free()
