extends AnimatedSprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
		play("astroid_rotating")
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_animation_finished() -> void:
	queue_free() # Replace with function body.
