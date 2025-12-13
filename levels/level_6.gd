extends LevelBase

func place_player_in_current_level(player: PlayerShip, player_id: int) -> void:
	# Level 6: DOWN_UP-Mode

	# 1) Grundzustände
	player.mode = player.FlightMode.DOWN_UP # 12.12.25 Modus wird angenommen
	player.rotation_degrees = 270
	player.collision_mask = (1 << 2) | (1 << 3) | (1 << 4) | (1 << 5)
	player.collision_layer = 1


	# 2) Positionierung mit base position links unten und je Spieler versetzter Offset
	var viewport_size: Vector2 = get_viewport_rect().size
	var base_position = viewport_size * 0.05
	var player_offset = Vector2(180 + 240 * (player_id - 1), 1840)
	player.global_position = base_position + player_offset

	# 3) Einheitliche Skalierung für Level 1
	player.scale = Vector2(0.25, 0.25)

	
	# 4) Sichtbar schalten
	player.show()
	
	
	# 5) richtige skin setzen
	player.set_skin("top_down")
	
