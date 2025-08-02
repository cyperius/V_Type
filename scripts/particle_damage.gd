extends GPUParticles2D



func _process(delta: float) -> void:
	amount_ratio = 1 - get_parent().health_ratio
