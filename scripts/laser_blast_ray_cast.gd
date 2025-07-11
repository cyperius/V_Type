extends RayCast2D

func _physics_process(_delta: float) -> void:
	if is_colliding():
		var collider = get_collider()
		print("colliding with: ", collider)
		if collider.is_in_group("evaders"):
			collider.evasive_mode_on = true
			await  get_tree().create_timer(0.2).timeout
			collider.evasive_mode_on = false
			
	
