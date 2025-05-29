extends Area2D

@export var health : int
@export var sfx_stream: AudioStream
@export var sfx_name : String
@export var weapon := PackedScene
@export var follow_path = false
@export var boss_soundtrack : AudioStream
@onready var audio2d = $AudioStreamPlayer2D
@export var damage : int = 50
@onready var explosion_animation = preload("res://scenes/explosion_animation.tscn").instantiate()

var shoot_timer = Timer.new()
var change_pos_timer = Timer.new()
var enemy_weapon = preload("res://scenes/enemy_shots_basic.tscn")
var projectiles = []
var game_over = preload("res://scripts/game_over.gd")
var new_y = 1000 # Globale Variable für die Zielposition
signal level_finished(level_nr : int)



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	area_entered.connect(_on_area_entered)
	# Timer konfigurieren:>>
	shoot_timer.wait_time = 2
	shoot_timer.one_shot = false
	shoot_timer.autostart = true
	add_child(shoot_timer) 
	shoot_timer.timeout.connect(_shot)
	audio2d.stream = boss_soundtrack
	fade_in_sound()
	
	var new_y = position.y
	change_pos_timer.wait_time = 2
	change_pos_timer.one_shot = false
	change_pos_timer.autostart = true
	add_child(change_pos_timer)
	change_pos_timer.timeout.connect(_position_change)
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	if Global.player_ship:
		var ship_sprite = Global.player_ship.get_node("ship_sprite")
		var player_position = ship_sprite.global_position
	# Kontrolle ob Player-Position ändert
		# print("player position", player_position) 
	else:
		print("Global.player_ship ist noch nicht gesetzt!")

	position.y = lerp(float(position.y), float(new_y), 0.05)
	position.x = lerp(float(position.x), float(2800), 0.005) # Bewegt sich langsam Richtung `new_y`
	
		
func _position_change() -> void:
		new_y = randi_range(position.y - 300, position.y + 300) 
		

func _shot() -> void:
	if sfx_stream:
		AudioManager.play_sfx(sfx_stream)
	else:
		AudioManager.play_sfx_string(sfx_name)
	_shoot(enemy_weapon)
# Funktion zum Abfeuern einer Waffe
# weapon: PackedScene - Die Szene des Projektils, das abgefeuert werden soll

func _shoot(weapon: PackedScene) -> void:
	# print("weapon fired")
	if not weapon:
		print("Fehler: Keine Waffe zugewiesen!")
		return
	var enemy_weapon = weapon
	# Instanziere das Projektil
	var projectile_instance1 = enemy_weapon.instantiate()
	var projectile_instance2 = enemy_weapon.instantiate()
	var projectile_instance3 = enemy_weapon.instantiate()
	
	# Verwende den Gunpoint als Referenz für den Startpunkt des Schusses
	var gunpoint1 = $Gunpoint1
	var gunpoint2 = $Gunpoint2
	var gunpoint3 = $Gunpoint3
	# Füge das Projektil der aktuellen Szene hinzu
	var current_scene = get_tree().current_scene
	if current_scene:
		# print("hello")
		if gunpoint1:
			# print("Gunpoint1 here")
			current_scene.add_child(projectile_instance1)
			projectile_instance1.global_position = gunpoint1.global_position
			
		else: 
			print("kein Gunpoint1 gefunden")
		if gunpoint2:
			current_scene.add_child(projectile_instance2)
			projectile_instance2.global_position = gunpoint2.global_position
		else: 
			print("kein Gunpoint2 gefunden")
		if gunpoint3:
			current_scene.add_child(projectile_instance3)
			projectile_instance3.global_position = gunpoint3.global_position
		else: 
			print("kein Gunppoint3 gefunden")
		# print("✅ Projektil(e) erfolgreich zur Szene hinzugefügt!")
	else:
		print("Fehler: Keine aktuelle Szene gefunden!")
		# Fallback: Nutze die Schiffposition
		projectile_instance1.global_position = global_position
		print("Gunpoint nicht gefunden, nutze Schiffposition:", projectile_instance1.global_position)

	# Füge das Projektil der Liste aktiver Projektile hinzu
	projectiles.append(projectile_instance1)
	projectiles.append(projectile_instance2)
	projectiles.append(projectile_instance3)

	# Rufe, falls vorhanden, die fire()-Methode des Projektils auf
	if projectile_instance1.has_method("fire"):
		# print("Fire-Funktion wird aufgerufen!")
		projectile_instance1.fire()
	else:
		pass
		# print("Fehler: Projektil hat keine fire()-Methode!")
#
func _on_area_entered(area_that_entered: Area2D) -> void:
	# print("getroffen")
	var damage_inflicted = area_that_entered.damage
	enemy_is_hit(damage_inflicted)
	#
	#
func enemy_is_hit(damage) -> void:
	health -= damage
	if health <= 0:
		AudioManager.play_sfx_string("explosion", 25)
		get_tree().current_scene.add_child(explosion_animation)
		explosion_animation.position = global_position
		explosion_animation.scale = Vector2(25, 25)
		explosion_animation.speed_scale = 0.5
		queue_free()
		
	
func fade_in_sound(duration : float = 5):
	audio2d.volume_db = -80
	audio2d.play()
	var tween := create_tween()
	tween.tween_property(audio2d, "volume_db", 1, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
