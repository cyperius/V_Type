extends Area2D

signal enemy_destroyed(score: int, energy: int)

@onready var skin2 : Texture = preload("res://assets/graphic_elements/enemies/Zombee.png")
@onready var explosion_animation = preload("res://scenes/explosion_animation.tscn").instantiate()
@export var damage = 100
@export var score_count : int = 300
@export var energy_left : int = 20
@onready var looks: Sprite2D = $Looks
@onready var body_area: Area2D = %BodyArea
@onready var brain_area: Area2D = %BrainArea


func _ready() -> void:
	brain_area.area_entered.connect(_on_brain_area_entered)
	body_area.area_entered.connect(_on_body_area_entered)
	add_to_group("one_hit_enemies")
	add_to_group("enemies")
	

func _on_brain_area_entered(area: Area2D) -> void:
	AudioManager.play_sfx_string("explosion")
	get_tree().current_scene.add_child(explosion_animation)
	explosion_animation.position = global_position
	emit_signal("enemy_destroyed", score_count, energy_left)
	queue_free()
	

func _on_body_area_entered(area: Area2D) -> void:
	scale *= 1.1
	
	
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
