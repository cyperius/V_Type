extends Area2D

@export var health_points : int = 50
@export var damage = 100
@export var score_count : int = 300
@export var energy_left : int = 20

@onready var skin2 : Texture = preload("res://assets/graphic_elements/enemies/Zombee.png")
@onready var explosion_animation = preload("res://game_world/explosion_animation.tscn").instantiate()
@onready var looks: Sprite2D = $Looks
@onready var body_area: Area2D = %BodyArea
@onready var brain_area: Area2D = %BrainArea


func _ready() -> void:
	add_to_group("enemies")
	
	
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
	AudioManager.play_sfx_string("explosion")
	get_tree().current_scene.add_child(explosion_animation)
	explosion_animation.position = global_position
	hide()
	await get_tree().create_timer(0.05).timeout
	queue_free()
	
	
	
func set_skin2():
	print("Looks: ", looks)
	if looks == null:
		print("Looks ist noch nicht bereit!")
	else:
		looks.texture = skin2
		print("tada: skin2! .. ?")
	
func _process(delta: float) -> void:
	pass
	#print("Pfad_enemy Posotion: ", global_position)
