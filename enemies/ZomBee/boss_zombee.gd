class_name BossZombee extends Area2D

signal boss_defeated

@export var health := 10000
@export var helmet_max_health : int
@export var speed := 400
@export var accelaration := 1200
var closest_player : Node

@onready var explosion_scene : PackedScene = preload("res://scenes/explosion_animation.tscn")
@onready var vomit_particles: GPUParticles2D = %VomitParticles
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var body: Area2D = %Body
@onready var brain: Area2D = %Brain
@onready var vomit_timer: Timer = %VomitTimer
@onready var mouth: Area2D = %Mouth
@onready var body_sprite: Sprite2D = $BodySprite
@onready var helmet_sprite: Sprite2D = %HelmetSprite
@onready var helmet: Area2D = %Helmet
@onready var head: Sprite2D = %Head
@onready var anger_timer: Timer = %AngerTimer
@onready var timer: Timer = $Timer
@onready var vomit_hit_box: Area2D = %VomitHitBox

# Dictionary, das (in ready-Funktion) alle aktiven Spieler speichert, erreichbar über ihre ID
var players : Dictionary = {}
var direction 
var helmet_health


func _ready() -> void:
	add_to_group("enemies")
	# Durch alle registrierten Spieler in Global gehen
	for player_id in Global.player_ships.keys():
		var player = Global.get_player_ship(player_id)
		if player:
			# Spieler in das Dictionary eintragen
			players[player_id] = player
		
	timer.timeout.connect(_on_timer_timeout)
	helmet_health = helmet_max_health
	var shader_material := helmet_sprite.material as ShaderMaterial
	shader_material.set_shader_parameter("crack_strength", 0.0)
	var eyes_shader_material := body_sprite.material as ShaderMaterial
	eyes_shader_material.set_shader_parameter("red_color", 0.0)
	body.area_entered.connect(_on_body_area_entered)
	brain.area_entered.connect(_on_brain_area_entered)
	mouth.area_entered.connect(_on_mouth_area_entered)
	helmet.area_entered.connect(_on_helmet_area_entered)
	
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
	# hier noch anpassen, das wirklich der Spieler mit der kürzesten Distanz referenziert wird
	track_nearest_player()
	global_position += direction * speed * delta
	rotation = direction.angle() - PI
	
	
func _on_body_area_entered(area_that_entered: Area2D) -> void:
	if area_that_entered.is_in_group("projectiles"):
		angry_zombee()


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
	
	if closest_player:
		direction = global_position.direction_to(closest_player.global_position)


func angry_zombee() -> void:
	var eyes_shader_material := head.material as ShaderMaterial
	eyes_shader_material.set_shader_parameter("red_color", 1.0)
	# vomit_wave aktiviert Geschosse für Treffer Logik, sowie die vomit_particles
	# für den optischen Effekt (und deaktiviert wieder, wenn die wave durch ist)
	if not helmet:
		vomit_particles.lifetime = 7.3
	head.vomit_wave()
	#vomit_particles.emitting = true
	speed = 1000
	#vomit_timer.start()
	anger_timer.start()
	await anger_timer.timeout
	speed = 400
	#await vomit_timer.timeout 
	#vomit_particles.emitting = false
	eyes_shader_material.set_shader_parameter("red_color", 0.0)
	

func _on_brain_area_entered(area_that_entered: Area2D) -> void:
	if "damage" in area_that_entered:
		health -= area_that_entered.damage
	
	if health < 0:
		emit_signal("boss_defeated")
		var explosion_animation = explosion_scene.instantiate()
		get_tree().current_scene.add_child(explosion_animation)
		explosion_animation.global_position = global_position
		explosion_animation.scale = Vector2(50, 50)
		explosion_animation.speed_scale = 0.3
		queue_free()
	
	
func _on_helmet_area_entered(area_that_entered: Area2D) -> void:		
	apply_helmet_damage(area_that_entered.damage)
	print("hit the fucking helmet!!")
	print("helmet_health: ", helmet_health)


func _on_mouth_area_entered(area_that_entered: Area2D) -> void:
	if area_that_entered.is_in_group("projectiles"):
		angry_zombee()


func status_report() -> void:
	print("Zombee Position: ", global_position)
	print("Direction to player: ", direction)
	print("direction angle(): ", direction.angle())


func _on_timer_timeout() -> void:
	print("timeout")
	var eyes_shader_material := head.material as ShaderMaterial
	eyes_shader_material.set_shader_parameter("red_color", 1.0)
	await get_tree().create_timer(0.8).timeout
	if not helmet:
		vomit_particles.lifetime = 7.3
	head.vomit_wave()
	eyes_shader_material.set_shader_parameter("red_color", 0.0)
	
	
