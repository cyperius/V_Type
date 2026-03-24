extends "res://scripts/enemy_1.gd"

@export var trigger_distance: float = 200
@export var explosion_damage : int = 1000
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var damage_collision_shape: CollisionShape2D = %damage_collision_shape
@onready var visual_damage_explosion: Sprite2D = %visual_damage_explosion
@onready var explosion_area: Area2D = $explosion_area
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

var self_destruct_tween: Tween = null
var explosion_area_to_be : Vector2
var explosion_start_scale := Vector2(5, 5)
var damage_explosion_scene = preload("res://enemies&obstacles/damage_explosion.tscn")
@export var explosion_area_max_scale := Vector2(160, 160)

func _ready() -> void:
	super._ready()
	

func connect_signals() -> void:
	if current_level and current_level.has_signal("player_target_activated"):
		if not current_level.player_target_activated.is_connected(_on_target_player_activated):
			current_level.player_target_activated.connect(_on_target_player_activated)
			
	
func _on_target_player_activated() -> void:
	is_player_tracking_active = true
	y_speed = 150


func _on_area_entered(other: Area2D) -> void:
	if other.is_in_group("players"):
		if self_destruct_triggered: # sollte theoretisch immer getriggert sein, aber so
			damage_explode() # ist es noch klarer und flexibel für Anpassungen
		else:
			die()
	elif other.is_in_group("evaders"):    
		apply_damage(other.damage, other.player_shot_owner_id) # die player_shot_owner_id.. #(other.damage, other.player_shot_owner_id)
	# wird vom Schuss auf den Gegner übertragen
	else:
		if "damage" in other:
			if "owner_id" in other: 
				apply_damage(other.damage, other.owner_id)
			else: # fallback, falls wir keine owner_id haben 
				apply_damage(other.damage, -1)
		
			
		
func _process(delta: float) -> void:
	super(delta)  # führt den _process von enemy_1.gd aus
	
	if not is_instance_valid(player):
		return
	if global_position.distance_to(player.global_position) < trigger_distance and not self_destruct_triggered:
		trigger_self_destruct()

		
func trigger_self_destruct() -> void:
	is_player_tracking_active = true
	y_speed = 375
	x_speed = 375
	self_destruct_triggered = true # self_destruct als getriggert markieren -> kann nicht erneut ausgelöst werden
	audio_stream_player.play()
	self_destruct_tween = create_tween()
	var tween_duration := 5.6
	self_destruct_tween.set_parallel()
	self_destruct_tween.tween_property(sprite_2d, "self_modulate", Color(0.975, 0.009, 0.009, 1.0), tween_duration)
	self_destruct_tween.tween_method(_set_pitch_scale, 1.0, 4.0, tween_duration)
	self_destruct_tween.tween_method(_set_explosion_scale, explosion_start_scale, explosion_area_max_scale, tween_duration)
	await self_destruct_tween.finished
	damage_explode()


func _set_pitch_scale(pitch_value: float) -> void:
	audio_stream_player.pitch_scale = pitch_value


func _set_explosion_scale(explosion_scale: Vector2) -> void:
	explosion_area_to_be = explosion_scale
	print("explotion_area_to_be: ", explosion_area_to_be)


func damage_explode() -> void:
	self_destruct_tween.kill()
	var damage_explosion = damage_explosion_scene.instantiate()
	damage_explosion.global_position = global_position
	get_tree().current_scene.add_child(damage_explosion)
	queue_free()
	

func apply_damage(damage_amount, owner_id) -> void: # Methode vom vererbten Script überschreiben,
	# wegen erweiterter Logik mit explosion_damage
	# damage_dealt begrenzen, wenn HP auf 0 sind (wegen Score)
	var damage_dealt = clamp(damage_amount, 0, health_points) # Invalid type in utility function "clamp()". Cannot convert argument 2 from int to Nil.
	health_points -= damage_dealt
	# Punktzahl in Abhängigkeit vom zugefügten Schaden, aktuell simpel 1:1
	var score = damage_dealt
	GameManager._on_enemy_hit(score, energy_left, owner_id)
	if health_points <= 0:
		if not self_destruct_triggered:
			die() # die() auslösen, ausser der Gegner ist bereits im self destruct Mode
		else:
			damage_explode()
	
