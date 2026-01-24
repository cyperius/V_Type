extends TileMapLayer

func _process(delta: float) -> void:
	position.x -= int(500 * delta)
	pass
