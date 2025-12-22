extends RayCast2D

@onready var laser_blast: Area2D = $".."


func _physics_process(_delta: float) -> void:
	if is_colliding():
		var collider = get_collider()
		print("colliding with: ", collider)
		if collider.is_in_group("evaders"): 
			# gegebenfalls Signal beim Collider auslösen und Position des Schusses mitgeben
			# um ebtsprechendes Ausweicheverhalten zu aktivieren
			if collider.has_signal("collision_detected"): 
				collider.emit_signal("collision_detected", laser_blast.global_position)
			collider.evasive_mode_on = true
			if "player_shot_owner_id" in collider:  # diese Mechanik noch bei Bossen einrichten, bei gegenr die nicht auf enemy.gd basieren
				collider.player_shot_owner_id = laser_blast.owner_id # dem Ausweicher wird
				# die owner_id des Schusses übertragen, so dass der sie weitergeben kann 
				# und der Kolletralschaden aufs Punkte Konto des verursachers geht
				await get_tree().create_timer(0.2).timeout
				if collider:
					collider.evasive_mode_on = false  # 17.12.2025 Im Moment ist mir unklar, wieso hier 
					# der evasive_mode ausgeschaltet wird, 21.12.25 evtl. wahrscheinlioch, damit nur einmal ein ausweichmanöver gemacht wird
					# und er dann wieder in den normalmodus geht
			
	
