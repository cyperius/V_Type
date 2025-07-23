class_name BossZombee extends Area2D

@export var health := 10000
@export var speed := 300
@export var accelaration := 1200

@onready var explosion_scene : PackedScene = preload("res://scenes/explosion_animation.tscn")
@onready var vomit_particles: GPUParticles2D = %VomitParticles
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var body: Area2D = %Body
@onready var brain: Area2D = %Brain
@onready var vomit_timer: Timer = %VomitTimer
@onready var mouth: Area2D = %Mouth
@onready var sprite_2d: Sprite2D = $BodySprite
@onready var helmet_sprite: Sprite2D = %HelmetSprite




var direction 

func _ready() -> void:
	var shader_material := helmet_sprite.material as ShaderMaterial
	shader_material.set_shader_parameter("crack_strength", 0.0)
	body.area_entered.connect(_on_body_area_entered)
	brain.area_entered.connect(_on_brain_area_entered)
	mouth.area_entered.connect(_on_mouth_area_entered)
	body.damage = 300
	mouth.damage = 600
	brain.damage = 300


func apply_helmet_damage(damage: float):
	var shader_material := helmet_sprite.material as ShaderMaterial
	var current_strength : float = shader_material.get_shader_parameter("crack_strength")
	var new_strength : float = clamp(current_strength + damage * 0.0002, 0.0, 1.0)
	shader_material.set_shader_parameter("crack_strength", new_strength)
	if new_strength == 1:
		helmet_sprite.hide()
		var explosion_animation = explosion_scene.instantiate()
		get_tree().current_scene.add_child(explosion_animation)
		explosion_animation.global_position = helmet_sprite.global_position
		explosion_animation.scale = Vector2(10, 10)
		explosion_animation.speed_scale = 0.8

func _process(delta: float) -> void:
	
	if Input.is_action_just_pressed("status_report"):
		status_report()
	
	var player_position = Global.player_ship.global_position
	direction = global_position.direction_to(player_position)
	global_position += direction * speed * delta
	rotation = direction.angle() - PI
	
	
func _on_body_area_entered(area_that_entered: Area2D) -> void:
	vomit_particles.emitting = true
	vomit_timer.start()
	await vomit_timer.timeout 
	vomit_particles.emitting = false
	
	
	#var tween = create_tween()
	#tween.tween_property(self, "modulate", Color(1, 0, 0), 1).set_trans(6).from_current()
	#tween.set_loops(1)
	
	
func _on_brain_area_entered(area_that_entered: Area2D) -> void:
	if "damage" in area_that_entered:
		health -= area_that_entered.damage
		if helmet_sprite.visible == true:
			apply_helmet_damage(area_that_entered.damage)
	if health < 0:
		var explosion_animation = explosion_scene.instantiate()
		get_tree().current_scene.add_child(explosion_animation)
		explosion_animation.global_position = global_position
		explosion_animation.scale = Vector2(50, 50)
		explosion_animation.speed_scale = 0.3
		queue_free()
		

func _on_mouth_area_entered(area_that_entered: Area2D) -> void:
	if "damage" in area_that_entered:
		health -= area_that_entered.damage
		if helmet_sprite.visible == true:
			apply_helmet_damage(area_that_entered.damage)
	

func status_report() -> void:
	print("Zombee Position: ", global_position)
	print("Direction to player: ", direction)
	print("direction angle(): ", direction.angle())
