extends "res://scripts/enemy_1.gd"


func connect_signals() -> void:
	if current_level and current_level.has_signal("player_target_activated"):
		if not current_level.player_target_activated.is_connected(_on_target_player_activated):
			current_level.player_target_activated.connect(_on_target_player_activated)

	
func _on_target_player_activated() -> void:
	is_player_tracking_active = true
	y_speed = 100

func _on_area_entered(other: Area2D) -> void:
	if other is PlayerShip:
		die()
	elif other.is_in_group("evaders"):    
		apply_damage(other.damage, player_shot_owner_id) # die player_shot_owner_id..
	# wird vom Schuss auf den Gegner übertragen
	else:
		if "damage" in other and "owner_id" in other:
			apply_damage(other.damage, other.owner_id)
		
		
