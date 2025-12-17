extends RayCast2D

@onready var laser_blast: Area2D = $".."


func _physics_process(_delta: float) -> void:
	if is_colliding():
		var collider = get_collider()
		print("colliding with: ", collider)
		if collider.is_in_group("evaders"):
			collider.evasive_mode_on = true
			collider.player_shot_owner_id = laser_blast.owner_id # dem Ausweicher wird
			# die owner_id des Schusses übertragen, so dass der sie weitergeben kann 
			# und der Kolletralschaden aufs Punkte Konto des verursachers geht
			await get_tree().create_timer(0.2).timeout
			if collider:
				collider.evasive_mode_on = false  # 17.12.2025 Im Moment ist mir unklar, wieso hier 
				# der evasive_mode ausgeschaltet wird 
			
	
