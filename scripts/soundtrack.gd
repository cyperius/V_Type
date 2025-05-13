extends AudioStreamPlayer

@onready var music_player = $"."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#music_player.stream = preload("res://assets/sound_and_sfx/soundtracks/through_space.wav")
	#music_player.play()
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
