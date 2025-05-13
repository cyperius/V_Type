extends Sprite2D

func _process(delta: float) -> void:
	if Global.player_ship:
		var ship_sprite = Global.player_ship.get_node("ship_sprite")
		var player_position = ship_sprite.global_position
		print("player position", player_position)
		
		# Berechne den neuen x-Wert:
		var new_x = lerp(position.x, player_position.x, 0.3 * delta)
		# Setze die neue Position, wobei die y-Komponente unverändert bleibt:
		self.position = Vector2(new_x, position.y)
		
		print("Gegnerposition:", position.x)
	else:
		print("Global.player_ship ist noch nicht gesetzt!")
