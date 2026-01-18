extends Boss

signal collision_detected(collision_position: Vector2)
signal been_hit

# boss stats

# speed and movement
@export var basic_speed := 700
@onready var speed = basic_speed * GameManager.loop_counter

# weapon system

#shield system
@onready var _particles_shield: GPUParticles2D = $ParticlesShield
@onready var _shield_area_2d: Area2D = $ShieldArea2D
@onready var _shield_collision_shape: CollisionShape2D = %ShieldCollisionShape2D


# sound and graphics
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var shot_stream_player_2d: AudioStreamPlayer2D = $ShotStreamPlayer2D
@export var normal_soundtrack : AudioStream
@export var lost_control_soundtrack : AudioStream


# specifications for movement and behaviour
@export var boarder_margin : int = 50
@onready var viewport_size = get_viewport_rect().size
@onready var corner_left_up := Vector2(boarder_margin, boarder_margin)
@onready var corner_left_down := Vector2(boarder_margin, viewport_size.y - boarder_margin)
@onready var corner_right_down := Vector2(viewport_size.x - boarder_margin, viewport_size.y - boarder_margin)
@onready var corner_right_up := Vector2(viewport_size.x - boarder_margin, boarder_margin)
@onready var corners := [corner_left_down, corner_left_up, corner_right_down, corner_right_up]
var next_corner 
var corner_reached := false
var target_corner : Vector2
var lost_control:= false
var start_health_points : int 
var health_ratio : float # 25.12.2025: wird in der process function aktuell gehalten
# besser wäre es nur bei einem Treffer berechen zu lassen..
var lost_control_timer : Timer = Timer.new()

# weitere Funktionalitäten bei Bedarf


func _ready() -> void:
	been_hit.connect(_on_been_hit)
	add_to_group("evaders")
	collision_detected.connect(_on_collision_detected)
	_shield_collision_shape.disabled = true
	_shield_area_2d.area_entered.connect(_on_shield_area_entered)
	start_health_points = health_points
	health_ratio = health_points / start_health_points
	print("health_points: ", health_points, "start_health_points= ", start_health_points, "health_ratio = ", health_ratio)
	lost_control_timer.wait_time = 20 # wird in process_function aktiviert wenn health_ratio
	audio_stream_player.stream = normal_soundtrack 
	audio_stream_player.play()
	fly_to_next_corner()
	super._ready() 
	
	
func _process(delta: float) -> void:
		
			
	if lost_control:
		rotation_degrees += 200 * delta
		global_position = global_position.move_toward(next_corner, (basic_speed / 2) * delta)
		if global_position == next_corner:
			fly_to_next_corner()
	
	else:
		if not evasive_mode_on:
			global_position = global_position.move_toward(Vector2(0.5 * viewport_size.x, 0.25 * viewport_size.y), basic_speed * delta)
		elif evasive_mode_on:
			global_position = global_position.move_toward(target_corner, 2 * basic_speed * delta)
		if global_position == corner_right_up or global_position == corner_left_up:
			evasive_mode_on = false


func fly_to_next_corner() -> void:
	next_corner = corners.pick_random()
	direction = global_position.direction_to(next_corner)


func _on_shoot_timer_timeout():
	if randi_range(1, chance_of_shooting) == 1:
		shot_stream_player_2d.volume_db = -10
		shot_stream_player_2d.play()
		var shot = shot_scene.instantiate()
		shot.global_position = global_position
		get_parent().add_child(shot)
		
		
func _on_collision_detected(shot_type: Node, collision_spot):
	if not lost_control:
		if shot_type is LaserBeam: # wenn der Schuss ein Laserbeam: evasive_mode aktivieren
			evasive_mode_on = true        # und Fluchtziel aufgrund Schussposition bestimmen
			if global_position.x - collision_spot.x > 0:
				target_corner = corner_right_up
			else:
				target_corner = corner_left_up
		if shot_type is LaserBlast:
			if shot_type.global_position.y > global_position.y + 350:
				activate_shield()
		
		
		
func activate_shield() -> void:
	_particles_shield.emitting = true
	_shield_collision_shape.disabled = false
	#emit_signal("shield_toggled", player_id, true)
	await get_tree().create_timer(1.5).timeout
	_shield_collision_shape.disabled = true
	_particles_shield.emitting = false
	
	
func _on_shield_area_entered(other: Area2D) -> void:
	print("ufo.gd: ", other, "entered Area")
	other.queue_free()
	
	
func _on_been_hit() -> void:
	if health_points / start_health_points < 0.8:
		lost_control = true
		
		
func _on_area_entered(other: Area2D) -> void:
	if other.is_in_group("players"):
		var entered_player = other.get_parent()
		entered_player.apply_damage(entered_player.damage, entered_player.player_id)
	# kommenden Block allenfalls reaktivieren anpassen, falls Ausweichverhalten eine Rolle spielen soll
	#elif other.is_in_group("evaders"):    
		#apply_damage(other.damage, player_shot_owner_id) # die player_shot_owner_id..
# wird vom Schuss auf den Gegner übertragen. Aber es braucht noch einen Mecahnismus, der 
# player_shot_owner_id wieder zurück auf den Verursacher überträgt. bzw. am besten einen anderen Mechanismus, 
# dass der Colleteralscahden vom ersten "Dominostein" gesammelt und dann dem verursacher verrechnet wird
	else:
		if "damage" in other and "owner_id" in other:
			apply_damage(other.damage, other.owner_id)
			health_ratio = health_points / start_health_points
			print("been hit, health_ratio = ", health_ratio)
			if health_ratio <= 0.9 and health_ratio > 0.6 or health_ratio <= 0.5 and health_ratio > 0.1 :
				lost_control = true
				print("lost control")
				# ohne diese Zeile, würde der neue Soundtrack immer wieder von Neuem getriggert
				if audio_stream_player.stream == normal_soundtrack: 
					audio_stream_player.stream = lost_control_soundtrack
					audio_stream_player.play()
			else:
				lost_control = false
				rotation_degrees = 0
				if audio_stream_player.stream == lost_control_soundtrack:
					audio_stream_player.stream = normal_soundtrack
					audio_stream_player.play()
				
				
