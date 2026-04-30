class_name BossZombee extends Area2D

signal boss_defeated

@export var health_points := 10000
@export var helmet_max_health : int
@export var speed := 400
@export var accelaration := 1200
var closest_player : Node

@onready var explosion_scene : PackedScene = preload("res://game_world/explosion_animation.tscn")
@onready var vomit_particles: GPUParticles2D = %VomitParticles
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var body: Area2D = %Body
@onready var brain: Area2D = %Brain
@onready var vomit_timer: Timer = %VomitTimer
@onready var mouth: Area2D = %Mouth
@onready var body_sprite: Sprite2D = $BodySprite
@onready var helmet_sprite: Sprite2D = %HelmetSprite
@onready var helmet: Area2D = %Helmet
@onready var wings: Area2D = %Wings
@onready var head: Sprite2D = %Head
@onready var anger_timer: Timer = %AngerTimer
@onready var timer: Timer = $Timer
@onready var vomit_hit_box: Area2D = %VomitHitBox
@onready var space_ball : SpaceBall

# Dictionary, das (in ready-Funktion) alle aktiven Spieler speichert, erreichbar über ihre ID
var players : Dictionary = {}
var direction : Vector2
var helmet_health
var wings_paralyzed = false
var desired_rotation : float


func _ready() -> void:
	add_to_group("enemies")
	
	# Signal für Änderungen in player Anzahl verbinden
	Global.roster_changed.connect(update_active_players)
	# Durch alle registrierten Spieler in Global gehen
	update_active_players()
			
	var current_scene = get_tree().current_scene
	if current_scene.has_node("Ball"):
		space_ball = current_scene.get_node("Ball")
		
		
	timer.timeout.connect(_on_timer_timeout)
	helmet_health = helmet_max_health
	var shader_material := helmet_sprite.material as ShaderMaterial
	shader_material.set_shader_parameter("crack_strength", 0.0)
	var eyes_shader_material := body_sprite.material as ShaderMaterial
	eyes_shader_material.set_shader_parameter("red_color", 0.0)
	# bodyparts Signale verbinden 
	body.area_entered.connect(_on_body_area_entered)
	brain.area_entered.connect(_on_brain_area_entered)
	#mouth.area_entered.connect(_on_mouth_area_entered) # 26.12.2025: für den Moment deaktiviert, da zu schwierig
	helmet.area_entered.connect(_on_helmet_area_entered)
	wings.area_entered.connect(_on_wings_area_entered)
	
	body.damage = 300
	mouth.damage = 600
	brain.damage = 300
	
	vomit_particles.lifetime = 0.45 # wenn Helm zerstört Verlängerung auf 7.3

func apply_helmet_damage(damage: float):
	var shader_material := helmet_sprite.material as ShaderMaterial
	var current_strength : float = shader_material.get_shader_parameter("crack_strength")
	helmet_health -= damage
	# helmet_damage_ratio als Zahl zw. 0 und 1, so dass sich der Wert mit zuneh-
	# mendem Scahden 1 annähert
	var helmet_damage_ratio = 1 - (helmet_health / helmet_max_health)
	# folgende 2 Zeilen: mit zunehemndem Helmschaden, werden die Cracks im Helm deutlicher
	var new_strength : float = clamp(helmet_damage_ratio, 0.0, 1.0)
	shader_material.set_shader_parameter("crack_strength", new_strength)
	if new_strength >= 1:
		helmet.queue_free()
		var explosion_animation = explosion_scene.instantiate()
		get_tree().current_scene.add_child(explosion_animation)
		explosion_animation.global_position = helmet_sprite.global_position
		explosion_animation.scale = Vector2(10, 10)
		explosion_animation.speed_scale = 0.8


func _process(delta: float) -> void:
	
	if Input.is_action_just_pressed("status_report"):
		status_report()
		
	track_nearest_player() # immer den nächsten Spieler tracken für akurates Zielen
	if not vomit_particles.emitting:  # aber bewegen nur, wenn Flügel sich bewgen und gerade nicht gekotzt wird
		if wings_paralyzed == false: 
			global_position += direction * speed * delta
			desired_rotation = direction.angle() - PI
			rotation = lerp(rotation, desired_rotation, 0.1)
		
	
func _on_body_area_entered(area_that_entered: Area2D) -> void:
	if area_that_entered.is_in_group("projectiles"):
		angry_zombee()

func _on_wings_area_entered(other: Area2D) -> void:
	if other.is_in_group("projectiles"):
		wings.set_process(false)
		wings_paralyzed = true
		await get_tree().create_timer(6).timeout
		wings.set_process(true)
		wings_paralyzed = false


func update_active_players() -> void:
	print("BossZombee: player roster updated")
	players = {} # bestehdnen Dictionary leeren
	# dann neu bilden mit Spielern die registriert sind und nicht zerstört wurden
	for player_id in Global.player_ships.keys():
		if player_id in Global.destroyed_player_ids:
			pass
		else:
			var player = Global.get_player_ship(player_id)
			if player:
				# Spieler in das Dictionary eintragen
				players[player_id] = player
				print("player roster updated")
	closest_player = null


func track_nearest_player():
	# der naheliegenste player steht am Anfang noch nicht fest, daher: "null"
	closest_player = null
	# INF ist eine vordefnierte Konstante "Infinite". Sinn: 
	# erst Wert "unendlich" als Disztanz setzen, die dann durhc die nächste
	# gemessene (zwingend kleinere) Distanz ersetzt wird
	var min_distance = INF
	# Für jeden Spieler, die oben im dictionary players erfasst wurde, wird die 
	# Distanz zum Boss geprüft...
	for player_id in players.keys():
		var player = players[player_id]
		var dist = global_position.distance_to(player.global_position)
		# ...und wenn diese gemessene Distanz < ist als die bishr kleinste
		# Distanz, wird dies die neuste kleinste Distanz
		if dist < min_distance:
			min_distance = dist
			#...und der Spieler zu dem sie gehört ist der nahgelegenste Spieler
			closest_player = player
	if is_instance_valid(closest_player):
		if is_instance_valid(space_ball):
			if global_position.distance_to(space_ball.global_position) < global_position.distance_to(closest_player.global_position):
				if global_position.distance_to(space_ball.global_position) > 100:
					direction = global_position.direction_to(space_ball.global_position)
		else:
			if global_position.distance_to(closest_player.global_position) > 100:
				direction = global_position.direction_to(closest_player.global_position)
				


func angry_zombee() -> void:
	var eyes_shader_material := head.material as ShaderMaterial
	eyes_shader_material.set_shader_parameter("red_color", 1.0)
	# vomit_wave aktiviert Geschosse für Treffer Logik, sowie die vomit_particles
	# für den optischen Effekt (und deaktiviert wieder, wenn die wave durch ist)
	if not helmet:
		vomit_particles.lifetime = 7.3
	head.vomit_wave()
	vomit_particles.emitting = true
	speed = 800
	#vomit_timer.start()
	anger_timer.start()
	await anger_timer.timeout
	speed = 400
	await vomit_timer.timeout 
	vomit_particles.emitting = false
	eyes_shader_material.set_shader_parameter("red_color", 0.0)
	

func _on_brain_area_entered(area_that_entered: Area2D) -> void:
	if "damage" in area_that_entered:
		health_points -= area_that_entered.damage
	
	if health_points < 0:
		emit_signal("boss_defeated")
		var explosion_animation = explosion_scene.instantiate()
		get_tree().current_scene.add_child(explosion_animation)
		explosion_animation.global_position = global_position
		explosion_animation.scale = Vector2(50, 50)
		explosion_animation.speed_scale = 0.3
		
		queue_free()
	
	
func _on_helmet_area_entered(area_that_entered: Area2D) -> void:		
	apply_helmet_damage(area_that_entered.damage)
	

func _on_mouth_area_entered(area_that_entered: Area2D) -> void:
	if area_that_entered.is_in_group("projectiles"):
		angry_zombee()


func status_report() -> void:
	print("Zombee Position: ", global_position)
	print("Direction to player: ", direction)
	print("direction angle(): ", direction.angle())


func _on_timer_timeout() -> void:
	var eyes_shader_material := head.material as ShaderMaterial
	eyes_shader_material.set_shader_parameter("red_color", 1.0)
	await get_tree().create_timer(0.8).timeout
	if not helmet:
		vomit_particles.lifetime = 7.3
	head.vomit_wave()
	eyes_shader_material.set_shader_parameter("red_color", 0.0)
	
	
