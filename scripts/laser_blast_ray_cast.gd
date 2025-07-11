extends RayCast2D

func _physics_process(_delta: float) -> void:
	if is_colliding():
		var collider = get_collider()
		print("colliding with: ", collider)
		collider.position.y += 50
	
