extends "res://scripts/enemy_1.gd"

@export var trigger_distance: float = 200
@export var explosion_damage : int = 1000
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var damage_collision_shape: CollisionShape2D = %damage_collision_shape
@onready var visual_damage_explosion: Sprite2D = $explosion_area/visual_damage_explosion
@onready var explosion_area: Area2D = $explosion_area
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
var self_destruct_triggered := false


func connect_signals() -> void:
	if current_level and current_level.has_signal("player_target_activated"):
		if not current_level.player_target_activated.is_connected(_on_target_player_activated):
			current_level.player_target_activated.connect(_on_target_player_activated)
			
	
func _on_target_player_activated() -> void:
	is_player_tracking_active = true
	y_speed = 150


func _on_area_entered(other: Area2D) -> void:
	if other.is_in_group("players"):
		die()
	elif other.is_in_group("evaders"):    
		apply_damage(other.damage, player_shot_owner_id) # die player_shot_owner_id..
	# wird vom Schuss auf den Gegner übertragen
	else:
		if "damage" in other and "owner_id" in other:
			apply_damage(other.damage, other.owner_id)
		
		
func _process(delta: float) -> void:
	if global_position.distance_to(player.global_position) < trigger_distance and self_destruct_triggered == false:
		trigger_self_destruct()
		
		
func trigger_self_destruct() -> void:
	is_player_tracking_active = true
	self_destruct_triggered = true # self_destruct als getriggert markieren _> kann nicht erneut ausgelöst werden
	audio_stream_player.play()
	var tween = create_tween()
	tween.parallel()
	tween.tween_property(sprite_2d, "self_modulate", Color(0.975, 0.009, 0.009, 1.0), 1)
	tween.tween_method(_set_pitch_scale, 1.0, 4.0, 3.0)
	await tween.finished
	damage_explode()
	
	
func _set_pitch_scale(pitch_value: float) -> void:
	audio_stream_player.pitch_scale = pitch_value
	
func damage_explode() -> void:
	explosion_area.damage = explosion_damage # es wird eine Variable damage für den
	# explosion_area Node kreiert, um die API des player_ships zu bedienen
	var explosion_tween = create_tween() # das ExplosionsSprite wächst per tween auf die Endgrösse
	explosion_tween.tween_property(visual_damage_explosion, "scale", Vector2(30, 30), 0.3)
	damage_collision_shape.disabled = false # diese Collsionshape ist via Inspector deaktiert und wird
	# aktiviert, da die damage_explosion getriggertw urde
	await explosion_tween.finished # wenn der tween vorbei ist wird der enemy direkt gelöscht - nicht via die() Funktion
	queue_free()
	
