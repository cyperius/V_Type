extends Enemy

@onready var circle_size_change_timer: Timer = $CircleSizeChangeTimer
@onready var circle_center_speed_timer: Timer = $CircleCenterSpeedTimer

# Für Circle-Mode: Zentrum und Radius (allenfalls vom Level‐Script zuweisen)
var circle_center_position := Vector2.ZERO
var circle_radius := 450
var circle_center_speed = -15
# Interne Variable: aktueller Winkel auf dem Kreis
var angle := 0.0
@export var angular_speed : int = 4

#var dist_to_center


func _ready() -> void:
	super._ready()
	
	is_player_tracking_active = true
	circle_size_change_timer.timeout.connect(_circle_radius_change)
	circle_center_speed_timer.timeout.connect(_circle_center_speed_change)
	circle_center_position = global_position # mal als Platzhalter: die spawning_position (durch Enemy_Spawner)
	# soll circle_center_position sein, evtl. kasnn man den gegenr gleich nach dem Spawnen auf eine
	#nadere Position repositionieren und er fliegt dann in die Kreisbahn oder so
	
func _process(delta: float) -> void:
	
	if position.x < -300:
		queue_free()
		
	circle_center_position.x += circle_center_speed
	angle += angular_speed * delta

	# 2. Neue Position auf dem Kreis berechnen
	var offset := Vector2(cos(angle), sin(angle)) * circle_radius
	global_position = circle_center_position + offset
	

	# 3. Rotation setzen: Schiff zeigt immer radial nach außen
	rotation = angle + PI
	
	# 4. von process function von enemy_1 kopiert
	if is_player_tracking_active == true:
		track_nearest_player()

func _circle_radius_change() -> void:
	var new_circle_radius = randi_range(150, 600)
	var new_angular_speed = [-2, -5, 2, 5].pick_random()
	var c_radius_tween = create_tween()
	c_radius_tween.set_parallel()
	c_radius_tween.tween_property(self, "circle_radius", new_circle_radius, 0.3)
	c_radius_tween.tween_property(self, "angular_speed", new_angular_speed, 0.2)
	
func _circle_center_speed_change() -> void:
	circle_center_speed = randi_range(-5, -25)
	
func _on_shoot_timer_timeout(): # überschreibt gleichnamige Funktion in enemy_1.gd
	if randi_range(1, chance_of_shooting) == 1:
		audio_stream_player_2d.volume_db = -10
		audio_stream_player_2d.play()
		var shot = shot_scene.instantiate()
		shot.global_position = _gun_point.global_position
		shot.direction = direction # direction wird in enemy_1 in der Track_player Funtion gesetzt
		shot.shot_orientation = direction.angle()
		get_parent().add_child(shot)
