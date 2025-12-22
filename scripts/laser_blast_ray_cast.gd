extends RayCast2D

@onready var shot: Area2D = $".."


func _physics_process(_delta: float) -> void:
	if is_colliding():
		var collider = get_collider()
		print("colliding with: ", collider)
		if collider.is_in_group("evaders"): 
			# gegebenfalls Signal beim Collider auslösen und Position des Schusses mitgeben
			# um ebtsprechendes Ausweicheverhalten zu aktivieren
			if collider.has_signal("collision_detected"): 
				collider.emit_signal("collision_detected", shot, shot.global_position)
			if "player_shot_owner_id" in collider:  # diese Mechanik noch bei Bossen einrichten, bei gegenr die nicht auf enemy.gd basieren
				collider.player_shot_owner_id = shot.owner_id # dem Ausweicher wird
				# die owner_id des Schusses übertragen, so dass der sie weitergeben kann 
				# und der Kolletralschaden aufs Punkte Konto des verursachers geht
				await get_tree().create_timer(0.2).timeout
				
			
	
