extends LevelBase

func place_player_in_current_level(player: PlayerShip, player_id: int) -> void:
	# Level 1: Standard-FREE-Mode, Spawn in Viewport-Mitte + Offset

	# 1) Grundzustände
	player.mode = player.PlayerMode.FREE
	player.rotation_degrees = 270
	player.collision_mask = (1 << 2) | (1 << 3) | (1 << 4) | (1 << 5)
	player.collision_layer = 1

	# 2) Positionierung wie in Main: Mitte + je Spieler versetzter Offset
	var viewport_size: Vector2 = get_viewport_rect().size
	var base_position = viewport_size * 0.05
	var player_offset = Vector2(180, 60 + 240 * (player_id - 1))
	player.global_position = base_position + player_offset

	# 3) Einheitliche Skalierung für Level 1
	player.scale = Vector2(0.25, 0.25)

	# 4) Sichtbar schalten
	player.show()
