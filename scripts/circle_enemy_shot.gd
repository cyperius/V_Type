extends Area2D

@export var speed = 400
@export var damage = 10
@export var sfx_stream: AudioStream 

@onready var audio_stream_player_2d = $AudioStreamPlayer2D
@onready var speed_level : float = 0.8 + GameManager.loop_counter / 5

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
	
	# Schussrichtung vom Zentrum zur  Richtung des Gegners
	var shot_direction = Vector2.ZERO.direction_to(global_position)
	global_position += shot_direction * delta * 1000
	
	
	# funktioniert halbwegs, aber shclechte Variante
	if scale <= Vector2(4, 4) :
		scale += Vector2(2, 2) * delta
	
