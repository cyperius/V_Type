extends GPUParticles2D

func _process(delta: float) -> void:
	amount_ratio = 1 - Global.player_ship.health_ratio
