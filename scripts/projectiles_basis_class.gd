extends Area2D

@export var speed = 400
@export var damage = 10
@export var sfx_stream: AudioStream  # Editor-Zuweisung möglich
@export var sfx_name: String = ""  # Alternativer Name für AudioManager
@export var volume: float = 1
@export var level_soundtrack 

@onready var enemy_hit_scene : PackedScene = preload("res://scenes/hit.tscn")
@onready var offset = Global.player_ship.global_position - Global.player_ship.circle_center_position
@onready var angle = offset.angle()
var player_mode = Global.player_ship.mode


func _ready():
	set_process(true)  # Stelle sicher, dass _process() aktiv ist
	#if get_parent():
		#print("Projektil-Parent:", get_parent().name)
		#print("Parent globaler Transform:", get_parent().global_transform)
	#else:
		#print("Fehler: Projektil hat keinen Parent!")
	
	# Signal verbinden (Beachte den Funktionsnamen _on_area_entered)
	area_entered.connect(_on_area_entered)
	if Global.player_ship.PlayerMode.CIRCLE == Global.player_ship.PlayerMode.CIRCLE:
		rotate(angle)
		start_tweens()
	

func start_tweens():
	var center_tween = create_tween()
	center_tween.tween_property(self, "position", Global.player_ship.circle_center_position, 5000/(speed*3)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var shrink_tween = create_tween()
	shrink_tween.tween_property(self, "scale", Vector2(0.05, 0.05), 5000/(speed*3)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	


func _process(delta):
	match player_mode:
		Global.player_ship.PlayerMode.FREE:
			_process_horizontal(delta)
	match player_mode:
		Global.player_ship.PlayerMode.CIRCLE:
			_process_circle(delta)
			
func _process_horizontal(delta):
	position.x += speed * delta
	# print("Projektil bewegt sich! Position:", position)
	
	# Lösche Projektil, wenn es aus dem Bildschirm fliegt
	if position.x > 4000:  # Bildschirmbreite
		queue_free()
		
	
func _process_circle(delta):
	# im Circle Mode wird ein Tween ausgelöst, der auf scale < 0.1 schrumpfen lässt, dies wird hier ausgenutzt um die Schüsse zu löschen
	if scale < Vector2(0.1, 0.1):
		queue_free()
	
	
	
func _on_area_entered(area: Area2D):
	if not area.is_in_group("one_hit_enemies"):
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
