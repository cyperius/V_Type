extends Area2D

@export var speed = 400
@export var damage = 10
@export var sfx_stream: AudioStream 
@onready var audio_stream_player_2d = $AudioStreamPlayer2D
@onready var biological_parent = get_parent().get_node("CircleEnemy1")
@onready var center_position = biological_parent.circle_center_position
@onready var speed_level : float = 0.8 + GameManager.loop_counter / 5
@onready var direction_vector := Vector2(cos(biological_parent.global_position.x), sin(biological_parent.global_position.y))
#@onready var dist_to_center = biological_parent.dist_to_center

var projectiles = []  


func _ready() -> void:
	#print("origin_distnce ", dist_to_center)
	add_to_group("projectiles")
	audio_stream_player_2d.play(1)
	 #if get_parent():
			 #print("Projektil-Parent:", get_parent().name)
			 #print("Parent globaler Transform:", get_parent().global_transform)
	 #else:
		 #print("Fehler: Projektil hat keinen Parent!")


func _process(delta: float) -> void:
	rotate(0.05)
	# Schussrichtung: Gerade von center_position zum enemy verlängern
	
	# folgende 4 Zeilen anpassen
	
	global_position += direction_vector * delta * 1000
	#dist_to_center = sqrt(pow(offset.x, 2) + pow(offset.y, 2))
	#scaling_factor = dist_to_center/3000
	#scale = Vector2(scaling_factor, scaling_factor)
	#explosion_size = dist_to_center/200
	
	#position.x += speed * delta * speed_level
	#position.y += speed * delta
	
	# es wird auf den laufend aktualisierten Werte der Variablen des parent (welche sich in dessen process_function upgedated werden) zugegriffen
	#print("parent_dist to center: ", biological_parent.dist_to_center)
	#print("dist to center: ", dist_to_center)
	
	#print("scaling_factor: ", biological_parent.scaling_factor)
	print("shot_position: ", position)
