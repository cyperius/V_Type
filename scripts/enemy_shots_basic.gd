extends Area2D

@export var speed = 400
@export var damage = 10
@export var sfx_stream: AudioStream  
@onready var speed_level : float = 0.8 + GameManager.loop_counter / 5

var projectiles = []  

func _ready() -> void:
	add_to_group("projectiles")
	 #if get_parent():
			 #print("Projektil-Parent:", get_parent().name)
			 #print("Parent globaler Transform:", get_parent().global_transform)
	 #else:
		 #print("Fehler: Projektil hat keinen Parent!")


func _process(delta: float) -> void:
	position.x -= speed * delta * speed_level
	position.y = position.y
