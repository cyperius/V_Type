extends Area2D

@export var speed = 400
@export var damage = 10
@export var sfx_stream: AudioStream 

@onready var audio_stream_player_2d = $AudioStreamPlayer2D
@onready var speed_level : float = 0.8 + GameManager.loop_counter / 5
@onready var marker_2d: Marker2D = $Marker2D
@onready var shot_direction = Vector2.ZERO.direction_to(Vector2(randi_range(-360, 360),\
	randi_range(-360, 360)))

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
	# Schussrichtung: wird aktuell zufällig mit onready var shot_direction bestimmt
	# funktioniert, aber ist suboptimal für Gegenr, die nach weiter aussen kommen
	position += shot_direction * delta * 1000
	
	
	# funktioniert halbwegs, aber shclechte Variante
	if scale <= Vector2(4, 4) :
		scale += Vector2(2, 2) * delta
	
