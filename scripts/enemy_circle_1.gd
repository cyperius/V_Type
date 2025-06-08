extends "res://scripts/enemy_1.gd"

@onready var level_3 = $".."

# Für Circle-Mode: Zentrum und Radius (allenfalls vom Level‐Script zuweisen)
var circle_center_position := Vector2.ZERO
var circle_radius := 1.0
# Interne Variable: aktueller Winkel auf dem Kreis
var angle := 0.0
# Wie schnell sich der Winkel ändert (Radiant pro Sekunde)
@onready var angular_speed : float = level_3.winkel_geschwindigkeit


func _ready() -> void:
	var center_node = $"../Center"
	circle_center_position = center_node.global_position
	area_entered.connect(_on_area_entered)
	add_to_group("one_hit_enemies")


func _process(delta: float) -> void:
	
	angle += angular_speed * delta

	# 2. Neue Position auf dem Kreis berechnen
	var offset := Vector2(cos(angle), sin(angle)) * circle_radius
	global_position = circle_center_position + offset
	circle_radius *= 1.0025

	# 3. Rotation setzen: Schiff zeigt immer radial nach außen
	rotation = angle + PI
	
	# 4. Schiff wird grösser mit zunehmendem Abstand zum Zentrum (Perspektive)
	var dist_to_center = sqrt(pow(offset.x, 2) + pow(offset.y, 2))
	scale.x = dist_to_center/3000
	scale.y = dist_to_center/3000
	
	
	# 5. Schiff löschen, wenn es in einer nicht mehr sichtbarten Distanz ist
	if dist_to_center > 2500:
		queue_free()
