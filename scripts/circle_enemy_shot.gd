extends Area2D

@export var speed = 400
@export var damage = 10
@export var sfx_stream: AudioStream 
@onready var audio_stream_player_2d = $AudioStreamPlayer2D
@onready var biological_parent = get_parent().get_node("CircleEnemy1")
# das scheint so nicht zu funktioneiren
@onready var center = $Center
#@onready var center_position = Vector2.ZERO
@onready var speed_level : float = 0.8 + GameManager.loop_counter / 5
# funktioniert so nicht zuverlässig, wenn gegner imm falschen moment zerstörtb werden.-. stattdessen beim schiessen eper sognal die pos übermitteln
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
	# geht so nicht, kann nicht auf center.global_posizion zugreifen
	#var dist_to_center = sqrt(pow(global_position.x-center.global_position.x, 2) + pow(global_position.y-center.global_position.y, 2))
	#var scaling_factor = dist_to_center/1000
	#scaling_factor += Vector2(dist_to_center, dist_to_center) * delta
	
	# funktioniert halbwegs, aber shclechte Variante
	if scale <= Vector2(4, 4) :
		scale += Vector2(2, 2) * delta
	
	
	
	#position.x += speed * delta * speed_level
	#position.y += speed * delta
	
	# es wird auf den laufend aktualisierten Werte der Variablen des parent (welche sich in dessen process_function upgedated werden) zugegriffen
	#print("parent_dist to center: ", biological_parent.dist_to_center)
	#print("dist to center: ", dist_to_center)
	
	#print("scaling_factor: ", biological_parent.scaling_factor)
	#print("shot_position: ", position)
