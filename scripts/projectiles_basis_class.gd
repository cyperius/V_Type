extends Area2D

@export var speed = 400
@export var damage = 10
@export var sfx_stream: AudioStream  # Editor-Zuweisung möglich
@export var sfx_name: String = ""  # Alternativer Name für AudioManager
@export var volume: float = 1

@onready var enemy_hit_scene : PackedScene = preload("res://scenes/hit.tscn")


func _ready():
	set_process(true)  # Stelle sicher, dass _process() aktiv ist
	#if get_parent():
		#print("Projektil-Parent:", get_parent().name)
		#print("Parent globaler Transform:", get_parent().global_transform)
	#else:
		#print("Fehler: Projektil hat keinen Parent!")
	
	# Signal verbinden (Beachte den Funktionsnamen _on_area_entered)
	area_entered.connect(_on_area_entered)

func _process(delta):
	position.x += speed * delta
	# print("Projektil bewegt sich! Position:", position)
	
	# Lösche Projektil, wenn es aus dem Bildschirm fliegt
	if position.x > 4000:  # Bildschirmbreite
		queue_free()
	
func _on_area_entered(area: Area2D):

	var enemy_hit = enemy_hit_scene.instantiate()
	get_tree().current_scene.add_child(enemy_hit)
	enemy_hit.position = global_position
	
	if area.is_in_group("asteroids"):
		# Hier kommt später die Schadenslogik hin
		queue_free()
	
	else:
		queue_free()

func fire():
	if sfx_stream:
		AudioManager.play_sfx(sfx_stream, volume)  # Falls direkte Datei-Zuweisung, diese nutzen
	elif sfx_name != "":
		AudioManager.play_sfx_string(sfx_name, volume)  # Falls kein AudioStream, nutze Namen aus AudioManager
