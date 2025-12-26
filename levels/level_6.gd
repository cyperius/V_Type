extends LevelBase


func _process(delta: float) -> void:
	# Sicherheitsabfrage, ob mind. 1 enemy gespawnt ist (nur damit genug Zeit da ist, um in current_level
	# den aktuellen level zu referenzieren und ob "amount_of_ememies" existiert 
	if enemy_spawner.at_least_one_enemy_spawned:
		if enemy_spawner.enemy_counter >= amount_of_enemies and enemy_spawner.boss_spawned == false:
			enemy_spawner.boss_spawned = true
			await get_tree().create_timer(8).timeout
			enemies_container.emit_signal("chance_of_behaviour_chance_changed", 1)
			await get_tree().create_timer(8).timeout
			enemy_spawner.here_comes_the_boss()
			
