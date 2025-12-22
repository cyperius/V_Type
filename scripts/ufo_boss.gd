extends Boss

signal collision_detected(collision_position: Vector2)

# boss stats

# speed and movement
@export var basic_speed := 700
@onready var speed = basic_speed * GameManager.loop_counter

# weapon system

# sound and graphics
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var shot_stream_player_2d: AudioStreamPlayer2D = $ShotStreamPlayer2D

# boss specific needs
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

# weitere Funktionalitäten bei Bedarf


func _ready() -> void:
	add_to_group("evaders")
	collision_detected.connect(_on_collision_detected)
	fly_to_next_corner()
	
	super._ready() # 20.12.2025 allenfalls wieder aktivieren, falls bei Umstellung auf basisboss-Klasse
	
	
func _process(delta: float) -> void:
	if lost_control:
		rotation_degrees += 200 * delta
		global_position = global_position.move_toward(next_corner, basic_speed * delta)
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
	print("ufo_boss.gd: flying to next corner")
	next_corner = corners.pick_random()
	direction = global_position.direction_to(next_corner)


func _on_shoot_timer_timeout():
	if randi_range(1, chance_of_shooting) == 1:
		shot_stream_player_2d.volume_db = -10
		shot_stream_player_2d.play()
		var shot = shot_scene.instantiate()
		shot.global_position = global_position
		get_parent().add_child(shot)
		
		
func _on_collision_detected(collision_spot):
	if global_position.x - collision_spot.x > 0:
		target_corner = corner_right_up
	else:
		target_corner = corner_left_up
	
