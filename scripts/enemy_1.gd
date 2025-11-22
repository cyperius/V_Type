class_name enemy extends Area2D

#signal enemy_destroyed(score: int, energy: int, player_id: int) # Signal wird neu direkt in GameManger aufgerufen
signal add_score (score: int)

@export var health_points: int = 10
@export var shot_sound : AudioStream 
@export var shot_scene : PackedScene
@export var damage = 100
@export var basic_speed : int = 50
@export var score_count : int = 100
@export var energy_left : int = 5

@onready var explosion_animation = preload("res://game_world/explosion_animation.tscn").instantiate()
@onready var explosion_size : float = 5
@onready var speed = basic_speed * GameManager.loop_counter
@onready var audio_stream_player_2d = $AudioStreamPlayer2D
@onready var _gun_point: Marker2D = %GunPoint
@onready var shoot_timer: Timer = $ShootTimer

var evasive_mode_on = false

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	add_to_group("one_hit_enemies")
	add_to_group("enemies")
	add_to_group("evaders")
	add_child(shoot_timer)
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	shoot_timer.start()
	audio_stream_player_2d.stream = shot_sound
	
	
func _on_area_entered(other: Area2D) -> void:
	if "damage" and "owner_id" in other: 
		apply_damage(other.damage, other.owner_id)
	
	
	
func _process(delta: float) -> void:
	if evasive_mode_on:
		position.y += delta * 950
	position.x -= delta * speed
	
	if position.x < -300:
		queue_free()
	

func _on_shoot_timer_timeout():
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
	GameManager.emit_signal("enemy_destroyed", score, energy_left, owner_id)
	if health_points <= 0:
		die()
		

func die() -> void:
	#AudioManager.play_sfx_string("explosion")
	get_tree().current_scene.add_child(explosion_animation)
	explosion_animation.position = global_position
	explosion_animation.scale = Vector2(explosion_size, explosion_size)
	# evtl.  noch prüfen, ob der Kollisionspartner ein PlayerShip ist
	
	print("enemy1.gd -line 39: enemy_destroyes_signal 
	HIER WIRD DIE PLAYER_ID AKTUELL ALS '1' UEBERGEBEN; ES BRAUCHT EIN SIGNAL VOM 
	SCHUSS; WELCHES DEN ENEMY TRIFFT; DER DIE PLAYER ID (OWNER_ID) WEITERREICHT")
	GameManager.emit_signal("enemy_destroyed", score_count, energy_left, 1)
	hide()
	await get_tree().create_timer(0.05).timeout
	queue_free()
