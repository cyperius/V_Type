extends enemy

signal just_touched_boarder

var hive_brain
var just_changed_direction = false
@onready var direction : int = -1

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	add_to_group("enemies")
	add_child(shoot_timer)
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	shoot_timer.start()
	audio_stream_player_2d.stream = shot_sound
	hive_brain = get_parent()
	hive_brain.change_direction.connect(_on_change_direction)
	

func _process(delta: float) -> void:
	position.x += delta * speed * direction
	if position.y > 2000:
		queue_free()	


func _on_area_entered(other: Area2D) -> void:
	print("I reached the boarder and I know it")
	connect("just_touched_boarder", hive_brain._on_just_touched_boarder)
	emit_signal("just_touched_boarder")
	if "damage" and "owner_id" in other: 
		apply_damage(other.damage, other.owner_id)
		
		
func _on_change_direction():
	if just_changed_direction:
		return
	just_changed_direction = true
	direction *= -1
	position.y += 100
	await get_tree().create_timer(0.5).timeout
	just_changed_direction = false
	
	
