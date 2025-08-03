extends Sprite2D

@export var vomit_bullet_scene : PackedScene

var last_target_position = Vector2.INF

@onready var vomit_particles: GPUParticles2D = %VomitParticles
@onready var head: Sprite2D = %Head
@onready var direction_2d : Vector2
@onready var boss_zombee: BossZombee = $".."



func _process(_delta: float) -> void:
	# Nur bei einem Wechsel des nahegelegensten Spielers look_at() ausführen, spart Rechenleistung
	if boss_zombee.closest_player and boss_zombee.closest_player.global_position != last_target_position:
		vomit_particles.look_at(boss_zombee.closest_player.global_position)
		last_target_position = boss_zombee.closest_player.global_position
	
	var material := vomit_particles.process_material as ParticleProcessMaterial
	material.direction = Vector3(1, 0, 0)  # Immer nach vorne (lokale +X-Richtung)
	material.initial_velocity_min = 300.0
	material.initial_velocity_max = 300.0
	material.spread = 0.0
	material.gravity = Vector3.ZERO
	
	
func spawn_vomit_bullet():
	var bullet = vomit_bullet_scene.instantiate() as Area2D
	get_tree().current_scene.add_child(bullet)
	bullet.look_at(boss_zombee.closest_player.global_position)
	bullet.global_position = head.global_position
	bullet.velocity = 5000.0 * bullet.global_position.direction_to(boss_zombee.closest_player.global_position)# oder andere Geschwindigkeit
	
	
	
func vomit_wave():
	for vomit_bullets in range(15):
		spawn_vomit_bullet()
		await get_tree().create_timer(0.03).timeout
