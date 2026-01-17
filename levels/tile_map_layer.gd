extends TileMapLayer

func _process(delta: float) -> void:
	position.x -= 100 * delta
