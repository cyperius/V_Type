extends Sprite2D
signal just_vomitted
@export var vomit_bullet_scene : PackedScene

var last_target_position = Vector2.INF
var vomit_wave_direction : Vector2

@onready var vomit_particles: GPUParticles2D = %VomitParticles
@onready var head: Sprite2D = %Head
@onready var direction_2d : Vector2
@onready var boss_zombee: BossZombee = $".."
@onready var helmet: Area2D = %Helmet



#func _ready() -> void:
	#just_vomitted.connect(_on_just_vomitted) # funktionierte bisher nicht gut

func _process(_delta: float) -> void:
	# 26.12.2025: bisher: Nur bei einem Wechsel des nahegelegensten Spielers look_at() ausführen, spart Rechenleistung
	if boss_zombee.closest_player and boss_zombee.closest_player.global_position != last_target_position:
		vomit_particles.look_at(boss_zombee.closest_player.global_position) # 26.12.2025:  vomit_wave_direction funktioniert nicht wie gewünscht
		last_target_position = boss_zombee.closest_player.global_position     # 26.12.2025: bisher 
		# vomit_wave_direction funktioniert nciht als Ziel,der Wert scheint sich ncciht zu ändern
	
		var material := vomit_particles.process_material as ParticleProcessMaterial
		material.direction = Vector3(1, 0, 0)  # Immer nach vorne (lokale +X-Richtung)
		material.initial_velocity_min = 300.0
		material.initial_velocity_max = 300.0
		material.spread = 0.0
		material.gravity = Vector3.ZERO
	
	
func spawn_vomit_bullet():
	if vomit_particles.emitting == false:
		return
	if not is_instance_valid(boss_zombee.closest_player):
		return
	var bullet = vomit_bullet_scene.instantiate() as Area2D
	get_tree().current_scene.add_child(bullet)
	if boss_zombee.closest_player.global_position:  # Sicherheitsnetz-> behebt hoffentlcih untenstehendes Problem
		bullet.look_at(boss_zombee.closest_player.global_position)  # als player zerstört wurde: Invalid access to property or key 'global_position' on a base object of type 'Nil'.
		bullet.global_position = head.global_position
		# bisheriger: jeder Schuss wird neu ausgerichtet - funktioniert besser (zu gut)
		bullet.velocity = 5000.0 * bullet.global_position.direction_to(boss_zombee.closest_player.global_position)# oder andere Geschwindigkeit
		# 26.12.2025: neu: in vomit_wave() gesetzte Richtung für Kotzstrahl gilt füer alle Kotzbrocken :)
		# bullet.velocity = 5000.0 * vomit_wave_direction # 26.12.2025 funktioniert nicht gut. Schüsse scheinen immer in selbe Richtung zu gehen
	
	
func vomit_wave():
	#vomit_wave_direction = head.global_position.direction_to(boss_zombee.closest_player.global_position) "26.12.25 funktioniert nicht gut
	#print("vomit_partcles.gd: vomit_wave_direction: ", vomit_wave_direction)
	vomit_particles.emitting = true
	#emit_signal("just_vomitted") * 26.12.2025: funktioniert damit auch nciht richtig leider
	for vomit_bullets in range(15):
		if not helmet: # nur wenn Helm zerstört ist, sollen collision areas abgesondert werden
			spawn_vomit_bullet()
		await get_tree().create_timer(0.03).timeout
	vomit_particles.emitting = false
	
	
#func _on_just_vomitted() -> void:
	
