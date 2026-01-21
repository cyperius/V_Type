extends TileMapLayer

func _process(delta: float) -> void:
	position.x -= int(100 * delta)
	pass
