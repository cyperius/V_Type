extends Path2D

@onready var path : PathFollow2D = $PathFollow2D
@onready var enemy_on_path = $PathFollow2D/Enemy

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	path.set_progress_ratio(1)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	path.progress_ratio -= delta * 0.2
	if path.progress_ratio <= 0:
		queue_free()
