extends enemy

func _process(delta: float) -> void:
	
	if position.x < -300:
		queue_free()
		
	position.x -= delta * speed
	position.y += delta * speed * direction.y
	
	track_nearest_player()
	
	if evasive_mode_on:
		position.y += delta * 2000
		position.x += delta * 1000
	
func track_nearest_player():
	# der naheliegenste player steht am Anfang noch nicht fest, daher: "null"
	closest_player = null
	# INF ist eine vordefnierte Konstante "Infinite". Sinn: 
	# erst Wert "unendlich" als Disztanz setzen, die dann durhc die nächste
	# gemessene (zwingend kleinere) Distanz ersetzt wird
	var min_distance = INF
	# Für jeden Spieler, die oben im dictionary players erfasst wurde, wird die 
	# Distanz zum Boss geprüft...
	for player_id in players.keys():
		var player = players[player_id]
		var dist = global_position.distance_to(player.global_position)
		# ...und wenn diese gemessene Distanz < ist als die bishr kleinste
		# Distanz, wird dies die neuste kleinste Distanz
		if dist < min_distance:
			min_distance = dist
			#...und der Spieler zu dem sie gehört ist der nahgelegenste Spieler
			closest_player = player

	if closest_player:
		if global_position.distance_to(closest_player.global_position) > 100:
			direction = global_position.direction_to(closest_player.global_position)
