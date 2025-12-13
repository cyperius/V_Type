extends enemy

signal just_touched_boarder

@export var breakout_speed : int = 500

var breakout_path_follow: PathFollow2D
var hive_brain
var just_changed_direction = false
var attack_mode := false
@onready var direction : int = -1
@onready var behaviour_timer: Timer = $BehaviourTimer
@onready var path_2d: Path2D = $Path2D


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	add_to_group("enemies")
	add_child(shoot_timer)
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	shoot_timer.start()
	audio_stream_player_2d.stream = shot_sound
	hive_brain = get_parent()
	hive_brain.change_direction.connect(_on_change_direction)
	behaviour_timer.timeout.connect(_on_behaviour_change)
	

func _process(delta: float) -> void:
	if not attack_mode:
		position.x += delta * speed * direction
		if position.y > 2000:
			queue_free()	
	else:
		breakout_path_follow.progress += breakout_speed * delta
		global_position = breakout_path_follow.global_position

func set_breakout_path_follow(path_follow: PathFollow2D) -> void:
	breakout_path_follow = path_follow


func _exit_tree() -> void:
	if breakout_path_follow != null and is_instance_valid(breakout_path_follow):
		breakout_path_follow.queue_free()
	breakout_path_follow = null


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
	var tween = create_tween()
	tween.tween_property(self, "position:y", global_position.y + 100, 0.2)
	direction *= -1
	await get_tree().create_timer(0.5).timeout
	just_changed_direction = false
	
	
func _on_behaviour_change() -> void:
	if randi_range(1, 12) == 1:
		breakout_path_follow = get_tree().root.get_node_or_null("Paths/BreakoutPathA/PathFollow2D")

		attack_mode = true
	
