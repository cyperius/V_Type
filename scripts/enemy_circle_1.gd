extends "res://scripts/enemy_1.gd"

#signal my_position(position: Vector2, scale: Vector2)

@export var circle_shot_scene : PackedScene
@onready var level_3 = $".."
@onready var angular_speed : float = level_3.winkel_geschwindigkeit * GameManager.loop_counter


# Für Circle-Mode: Zentrum und Radius (allenfalls vom Level‐Script zuweisen)
var circle_center_position := Vector2.ZERO
var circle_radius := 1.0
# Interne Variable: aktueller Winkel auf dem Kreis
var angle := 0.0

#var dist_to_center
var scaling_factor

func _ready() -> void:
	super._ready()
	var center_node = $"../Center" # Was hier referenziert Im parent dieses Nodes gibt es 
	# einen ChildNode (also ein Sibling dieses Nodes) der "Center" heisst
	circle_center_position = center_node.global_position
	
	
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
	scaling_factor = dist_to_center/3000
	scale = Vector2(scaling_factor, scaling_factor)
	death_module.explosion_size_x = dist_to_center/200
	death_module.explosion_size_y = dist_to_center/200
	
	
	# 5. Schiff löschen, wenn es in einer nicht mehr sichtbarten Distanz ist
	if dist_to_center > 2500:
		queue_free()


func _on_shoot_timer_timeout():
	# Je höher die Anz. Spieler, umso grösser die Chance, dass ein Schuss ausgelöst wird
	var shot_probability = randf_range(1, 3 - 0.5 * Global.player_ships.size())
	if shot_probability <= 1.8:
		audio_stream_player_2d.play()
		var shot = circle_shot_scene.instantiate()
		# scale des instantiierten Schusses entspricht dem scale des enemies (siehe oben 4.)
		shot.scale = scale
		shot.position = global_position
		# Schussinstanz dem Level übergeben, damit er nicht mit dem enemy mitrotiert
		var parent = get_parent()
		parent.add_child(shot)
		
