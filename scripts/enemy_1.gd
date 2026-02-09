class_name enemy extends Area2D

signal collision_detected(enemy: Node, collision_position: Vector2)

@export var health_points: int = 10
@export var shot_sound : AudioStream 
@export var shot_scene : PackedScene
@export var damage = 500
@export var x_basic_speed : int = 500
@export var y_basic_speed : int = 0
@export var score_count : int = 100
@export var energy_left : int = 5
@export var chance_of_shooting : int = 1

@onready var explosion_animation_scene = preload("res://game_world/explosion_animation.tscn")
@onready var explosion_size : float = 5
@onready var x_speed = x_basic_speed * GameManager.loop_counter
@onready var y_speed = y_basic_speed * GameManager.loop_counter
@onready var audio_stream_player_2d = $AudioStreamPlayer2D
@onready var _gun_point: Marker2D = %GunPoint
@onready var shoot_timer: Timer = $ShootTimer
@onready var space_ball : SpaceBall # für Angriff aus space_ball
@onready var current_level : Node # wird in ready_function gesetzt



var closest_player : Node
# Dictionary, das (in ready-Funktion) alle aktiven Spieler speichert, erreichbar über ihre ID
var players : Dictionary = {}
var direction : Vector2 = Vector2(-1, -1)
var evasive_mode_on = false
var player_shot_owner_id : int =- 1
var is_player_tracking_active := false
var player : PlayerShip



func _ready() -> void:
	area_entered.connect(_on_area_entered)
	add_to_group("enemies")
	add_to_group("evaders")
	collision_detected.connect(_on_collision_detected)
	
	if shoot_timer:
		shoot_timer.timeout.connect(_on_shoot_timer_timeout)
		shoot_timer.start()
	if audio_stream_player_2d:
		audio_stream_player_2d.stream = shot_sound
	
	
	current_level = get_tree().get_first_node_in_group("levels")
	
	# 1) -- für Angriff auf Spieler -- #
	# Durch alle registrierten Spieler in Global gehen
	for player_id in Global.player_ships.keys():
		player = Global.get_player_ship(player_id) as PlayerShip # player ist oben als globale Variable definiert
		if player:
			# Spieler in das Dictionary eintragen
			players[player_id] = player
	# 1) -- oben: für Angriff auf Spieler -- #
	
	
	# 2) -- für Angriff auf space_ball -- #
	var current_scene = get_tree().current_scene
	if current_scene.has_node("Ball"):
		space_ball = current_scene.get_node("Ball")
	# 2) -- oben: für Angriff auf space_ball -- #
	
	connect_signals()
	
func connect_signals() -> void:
	pass
	

func _on_area_entered(other: Area2D) -> void:
	if other.is_in_group("players"):
		var entered_player = other.get_parent()
		apply_damage(entered_player.damage, entered_player.player_id)
	elif other.is_in_group("evaders"):    
		apply_damage(other.damage, player_shot_owner_id) # die player_shot_owner_id..
# wird vom Schuss auf den Gegner übertragen. Aber es braucht noch einen Mecahnismus, der 
# player_shot_owner_id wieder zurück auf den Verursacher überträgt. bzw. am besten einen anderen Mechanismus, 
# dass der Colleteralscahden vom ersten "Dominostein" gesammelt und dann dem verursacher verrechnet wird
	else:
		if "damage" in other and "owner_id" in other:
			apply_damage(other.damage, other.owner_id)


func _on_collision_detected(shot_type: Node, collision_spot: Vector2):
	if shot_type is LaserBlast:
		var tween = get_tree().create_tween()
		tween.set_parallel()
		tween.tween_property(self, "position:x", global_position.x + 150, 0.2)
		tween.tween_property(self, "position:y", global_position.y + 300, 0.2)

	
func _process(delta: float) -> void:
	
	if position.x < -50:
		queue_free()
		
	position.x += delta * x_speed * direction.x
	position.y += delta * y_speed * direction.y
	
	
	#if "do_target_player" in current_level:
		#if current_level.do_target_player == true:
		
	if is_player_tracking_active == true:
		track_nearest_player()
	
	
	
func track_nearest_player():
	# der naheliegenste player steht am Anfang noch nicht fest, daher: "null"
	closest_player = null
	# INF ist eine vordefnierte Konstante "Infinite". Sinn: 
	# erst Wert "unendlich" als Disztanz setzen, die dann durch die nächste
	# gemessene (zwingend kleinere) Distanz ersetzt wird
	var min_distance = INF
	# Für jeden Spieler, die oben im dictionary players erfasst wurde, wird die 
	# Distanz zum Boss geprüft...
	for player_id in players.keys():
		var player = players[player_id]
		var dist = global_position.distance_to(player.global_position)
		# ...und wenn diese gemessene Distanz < ist als die bisher kleinste
		# Distanz, wird dies die neuste kleinste Distanz
		if dist < min_distance:
			min_distance = dist
			#...und der Spieler zu dem sie gehört ist der nahgelegenste Spieler
			closest_player = player

	if closest_player and closest_player.player_is_dead == false:
		if global_position.distance_to(closest_player.global_position) > 100:
			direction = global_position.direction_to(closest_player.global_position)



func _on_shoot_timer_timeout():
	if randi_range(1, chance_of_shooting) == 1:
		var visible_rect = CameraUtils.get_visible_world_rect(get_viewport())
		if visible_rect.has_point(global_position):
			audio_stream_player_2d.volume_db = -10
			audio_stream_player_2d.play()
			var shot = shot_scene.instantiate()
			shot.global_position = _gun_point.global_position
			get_parent().add_child(shot)
	

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
	var explosion_animation = explosion_animation_scene.instantiate()
	explosion_animation.global_position = global_position
	explosion_animation.scale = Vector2(explosion_size, explosion_size)
	get_tree().current_scene.add_child(explosion_animation)
	hide()
	await get_tree().create_timer(0.05).timeout
	queue_free()
