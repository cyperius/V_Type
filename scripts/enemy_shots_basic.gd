extends Area2D

@onready var hit_scene : PackedScene = preload("res://game_world/hit.tscn") # braucht es hit_scene beim player noch? vieleoicht schon für treffer des palyers?
@export var speed = 400
@export var damage = 10
@export var sfx_stream: AudioStream  
@onready var speed_level : float = 0.8 + GameManager.loop_counter / 5
@export var direction : Vector2 = Vector2(-1, 0)
@export var shot_orientation : float

var projectiles = []  

func _ready() -> void:
	add_to_group("projectiles")
	area_entered.connect(_on_area_entered)
	rotation = shot_orientation
	 #if get_parent():
			 #print("Projektil-Parent:", get_parent().name)
			 #print("Parent globaler Transform:", get_parent().global_transform)
	 #else:
		 #print("Fehler: Projektil hat keinen Parent!")


func _process(delta: float) -> void:
	position += direction * speed * delta * speed_level
	#rotation = direction.angle()
	
func _on_area_entered(other) -> void:
	if other.is_in_group("players"):
		# wenn ein Spieler getroffen wurde, Trefferszene auslösen und Schuss löschen
		var hit := hit_scene.instantiate()
		
		# 1) erst konfigurieren
		hit.global_position = global_position + direction * speed * 0.05
		hit.scale = Vector2(2, 2)

		# 2) dann hinzufügen
		get_tree().current_scene.add_child(hit)
		
	queue_free()
	
	
