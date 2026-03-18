class_name RadioModul extends Node

## empfängt externe Signale und verarbeitet oder leitet sie weiter ##



func _ready() -> void:
	# Shooter einmalig „snapshotten“ (robust, falls der Spieler den Tree verlässt)
	shooter = Global.get_player_ship(owner_id) as PlayerShip
	if shooter != null:
		circle_mode_enabled = (shooter.mode == shooter.FlightMode.CIRCLE) # circle_mode_enabled wird auf "true" gesetzt, falls der FlightMode entsprechnd gesetzt ist (was wiederum im jew. Level vorgenoommen wird)
		if circle_mode_enabled:
			# Richtung aus Spieler-Position relativ zum Kreiszentrum ableiten
			var offset: Vector2 = shooter.global_position - shooter.circle_center_position
			var angle: float = offset.angle()
			rotation = angle
			circle_center_position = shooter.circle_center_position
			start_tweens(angle)
		else:
			if shooter.mode == shooter.FlightMode.LEFT_RIGHT:
			# Linearer Schuss nach rechts (bei Bedarf später an Mündung/Rotation koppeln)
				velocity = Vector2.RIGHT.rotated(deg_to_rad(shooter.rotation_degrees)) * speed
				
			if shooter.mode == shooter.FlightMode.DOWN_UP:
			# Linearer Schuss nach oben
				velocity = Vector2.RIGHT.rotated(deg_to_rad(shooter.rotation_degrees)) * speed
				rotation_degrees = shooter.rotation_degrees
	else:
		# Fallback: linear nach rechts
		velocity = Vector2.RIGHT * speed
