extends "res://scripts/enemy_1.gd"



# Für Circle-Mode: Zentrum und Radius (allenfalls vom Level‐Script zuweisen)
var circle_center_position := Vector2.ZERO
var circle_radius := 1.0
# Interne Variable: aktueller Winkel auf dem Kreis
var angle := 0.0
# Wie schnell sich der Winkel ändert (Radiant pro Sekunde)
var angular_speed := 1.5


func _ready() -> void:
	var dist_to_center = sqrt(pow(0.3, 2) + pow(-0.2, 2))
	print(dist_to_center)
	var center_node = $"../Center"
	circle_center_position = center_node.global_position


func _process(delta: float) -> void:
	
	angle += angular_speed * delta

	# 2. Neue Position auf dem Kreis berechnen
	var offset := Vector2(cos(angle), sin(angle)) * circle_radius
	global_position = circle_center_position + offset
	circle_radius += 0.2

	# 3. Rotation setzen: Schiff zeigt immer radial nach außen
	rotation = angle + PI
