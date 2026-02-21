class_name Boss
extends Area2D

signal boss_defeated

@export var health_points: float = 10
@export var shot_sound : AudioStream 
@export var shot_scene : PackedScene
@export var damage = 500
@export var x_basic_speed : int = 500
@export var y_basic_speed : int = 0
@export var score_count : int = 100
@export var energy_left : int = 20
@export var chance_of_shooting : int = 1

@onready var explosion_animation_scene = preload("res://game_world/explosion_animation.tscn")
@onready var x_speed = x_basic_speed * GameManager.loop_counter
@onready var y_speed = y_basic_speed * GameManager.loop_counter
#@onready var audio_stream_player_2d = $AudioStreamPlayer2D
#@onready var _gun_point: Marker2D = %GunPoint
@onready var shoot_timer: Timer = $ShootTimer
@onready var gun_points: Node2D = $GunPoints
var projectile_instance # globale Variable für Schussinstanz

#@onready var space_ball : SpaceBall # für Angriff aus space_ball
#@onready var current_level : Node # wird in ready_function gesetzt

var rumble_intensity := 0.0
var explosion_animation : Node2D

var closest_player : Node
# Dictionary, das (in ready-Funktion) alle aktiven Spieler speichert, erreichbar über ihre ID
var players : Dictionary = {}
var direction : Vector2 = Vector2(-1, -1)
var evasive_mode_on = false
#var player_shot_owner_id : int =- 1
#var is_player_tracking_active := false


# ----

#@export var sfx_stream: AudioStream
#@export var weapon := PackedScene
@export var boss_soundtrack : AudioStream
@onready var audio2d = $AudioStreamPlayer2D

var change_pos_timer = Timer.new()
var enemy_weapon = preload("res://enemies&obstacles/enemy_utilities/enemy_shots_basic.tscn")
var projectiles = []
var new_y = 1000 # Globale Variable für die Zielposition




# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("enemies")
	area_entered.connect(_on_area_entered)
	audio2d.stream = boss_soundtrack
	fade_in_sound()
	add_to_group("enemies")
	
	var new_y = position.y
	change_pos_timer.wait_time = 2
	change_pos_timer.one_shot = false
	change_pos_timer.autostart = true
	add_child(change_pos_timer)
	change_pos_timer.timeout.connect(_position_change)
	
	shoot_timer.timeout.connect(_shot)
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	#if Global.player_ship:
		#var ship_sprite = Global.player_ship.get_node("ship_sprite")
		#var player_position = ship_sprite.global_position
	## Kontrolle ob Player-Position ändert
		## print("player position", player_position) 
	#else:
		#print("Global.player_ship ist noch nicht gesetzt!")

	position.y = lerp(float(position.y), float(new_y), 0.05)
	position.x = lerp(float(position.x), float(2800), 0.005) # Bewegt sich langsam Richtung `new_y`
	
		
func _position_change() -> void:
		new_y = clamp(randi_range(position.y - 300, position.y + 300), 200, 1800)
	
		
func _shot() -> void:
	if shot_sound:
		AudioManager.play_sfx(shot_sound)
	_shoot(shot_scene)
# Funktion zum Abfeuern einer Waffe
# weapon: PackedScene - Die Szene des Projektils, das abgefeuert werden soll

func _shoot(weapon: PackedScene) -> void:
	# print("weapon fired")
	if not weapon:
		#print("Fehler: Keine Waffe zugewiesen!")
		return
	var enemy_weapon = weapon
	# Instanziere das Projektil
	
	var current_scene = get_tree().current_scene
	if current_scene:
		var gun_points_positions : Array = gun_points.get_children()
		if gun_points_positions:
			for gunpoint in gun_points_positions: # pro defniertem GunPoint ein Projektil instantiieren
				var projectile_instance = enemy_weapon.instantiate()
				var gun_start_point = gunpoint.get_child(0, true) # prüfen, ob es einen GunStartPoint gibt
				var shot_direction : Vector2
				if gun_start_point: # wenn ja, Schussrichtung = Richtung GunStartPoint -> GunPoint
					#print("boss1.gd: found startGunPoint: ", gun_start_point)
					shot_direction = gunpoint.position.direction_to(gun_start_point.position)
					#print("boss1.gd: shot direction: = ", shot_direction)
					projectile_instance.direction = shot_direction 
					#print("boss1: projectile_instance.direction: ", projectile_instance.direction)
					projectile_instance.shot_orientation = shot_direction.angle()
				
				# Verwende gunpoints als Referenzen für Startpunkte des Schusses
				projectile_instance.global_position = gunpoint.global_position
				#print("boss1: projectile_instance.direction: ", shot_direction == projectile_instance.direction)
				current_scene.add_child(projectile_instance) # Füge das Projektil der aktuellen Szene hinzu
				# Füge das Projektil der Liste aktiver Projektile hinzu
				projectiles.append(projectile_instance)
		else: # wenn keine gunpoints -> Fallback: Nutze die Schiffposition
			var projectile_instance = enemy_weapon.instantiate()
			projectile_instance.global_position = global_position
			#print("boss1.gd: Gunpoint nicht gefunden, nutze Schiffposition:", projectile_instance.global_position)
			
			current_scene.add_child(projectile_instance) #
			
	else:
		#print("boss1.gd: Fehler: Keine aktuelle Szene gefunden!")
		
		# Rufe, falls vorhanden, die fire()-Methode des Projektils auf
		if projectile_instance.has_method("fire"):
			#print("boss1.gd: Fire-Funktion wird aufgerufen!")
			projectile_instance.fire()
		else:
			pass
			#print("boss1.gd: Fehler: Projektil hat keine fire()-Methode!")
	
	
func _on_area_entered(other: Area2D) -> void:
	if other.is_in_group("players"):
		apply_damage(other.damage, -1)
	# kommenden Block allenfalls reaktivieren anpassen, falls Ausweichverhalten eine Rolle spielen soll
	#elif other.is_in_group("evaders"):    
		#apply_damage(other.damage, player_shot_owner_id) # die player_shot_owner_id..
# wird vom Schuss auf den Gegner übertragen. Aber es braucht noch einen Mecahnismus, der 
# player_shot_owner_id wieder zurück auf den Verursacher überträgt. bzw. am besten einen anderen Mechanismus, 
# dass der Colleteralscahden vom ersten "Dominostein" gesammelt und dann dem verursacher verrechnet wird
	else:
		if "damage" in other and "owner_id" in other:
			apply_damage(other.damage, other.owner_id)
	
		
func apply_damage(damage_amount, owner_id) -> void:
	# damage_dealt begrenzen, wenn HP auf 0 sind (wegen Score)
	var damage_dealt = clamp(damage_amount, 0, health_points)
	health_points -= damage_dealt
	# Punktzahl in Abhängigkeit vom zugefügten Schaden, aktuell simpel 1:1
	var score = damage_dealt
	GameManager._on_enemy_hit(score, energy_left, owner_id)
	if health_points <= 0:
		die()
	
		
func die() -> void:
	AudioManager.play_sfx_string("explosion", 25)
	explosion_animation = explosion_animation_scene.instantiate() as ExplosionAnimation
	get_tree().current_scene.add_child(explosion_animation)
	explosion_animation.position = global_position
	explosion_animation.scale = Vector2(25, 25)
	explosion_animation.speed_scale = 0.3
	
	# sicher unnötig komplizierte, aber funktionierende Referenz zu aktive Controllern
	var controller_ids := Players.get_active_player_ids() # diese Funktion in Players generiert einen Array mit player_ids, welche mit 1 starten (aber keine int sind)
	var array_with_controller_ids : Array[int] # Für die folgende rumble() - Funktion müssen die Controller ID's mit einem Array mit Int-Elementen übergeben werden
	for number in controller_ids:  # daher werden die Nummern aus dem array "controller_ids" zu int-Werten umgewandelt
		var int_number = int(number) # man könnte wohl auch einfach mit "number = int(number)" direkt umwandeln
		int_number -= 1 # die ursprünglichen player_ids begannen mit 1 -> Korrektur um -1
		array_with_controller_ids.append(int_number) # und die nun passenden Elemnte dem array "array_with_controller_ids" hinzufügen
	
	RumbleManager.rumble(2.5, 1)  
	
	
	emit_signal("boss_defeated")
	await get_tree().create_timer(0.05).timeout
	queue_free()



func fade_in_sound(duration : float = 5):
	audio2d.volume_db = -80
	audio2d.play()
	var tween := create_tween()
	tween.tween_property(audio2d, "volume_db", 10, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
