extends enemy

signal just_touched_boarder

@export var breakout_speed: int = 500

var breakout_path_follow: PathFollow2D = null
var hive_brain: Node = null
var just_changed_direction: bool = false
var attack_mode: bool = false

@onready var direction: int = -1
@onready var behaviour_timer: Timer = $BehaviourTimer


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	add_to_group("enemies")

	add_child(shoot_timer)
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	shoot_timer.start()

	audio_stream_player_2d.stream = shot_sound

	hive_brain = get_parent()
	if hive_brain and hive_brain.has_signal("change_direction"):
		hive_brain.change_direction.connect(_on_change_direction)

	# Signal nur EINMAL verbinden (nicht bei jedem Border-Touch)
	just_touched_boarder.connect(hive_brain._on_just_touched_boarder)

	behaviour_timer.timeout.connect(_on_behaviour_change)


func _process(delta: float) -> void:
	if not attack_mode:
		position.x += delta * speed * direction
		if position.y > 2000:
			queue_free()
		return

	# --- Attack / Breakout Mode ---
	if breakout_path_follow == null or not is_instance_valid(breakout_path_follow):
		attack_mode = false
		push_warning("attack_mode war true, aber breakout_path_follow ist null/ungueltig.")
		return

	breakout_path_follow.progress += breakout_speed * delta
	global_position = breakout_path_follow.global_position


func set_breakout_path_follow(path_follow: PathFollow2D) -> void:
	breakout_path_follow = path_follow


func _exit_tree() -> void:
	# Follow aufraeumen, damit nicht unsichtbare Follows im Path2D liegen bleiben
	if breakout_path_follow != null and is_instance_valid(breakout_path_follow):
		breakout_path_follow.queue_free()
	breakout_path_follow = null


func _on_area_entered(other: Area2D) -> void:
	emit_signal("just_touched_boarder")

	#if "damage" and "owner_id" in other: 
		#apply_damage(other.damage, other.owner_id)


func _on_change_direction() -> void:
	# Ausbrecher sollen NICHT mehr von der Formation umgedreht werden
	if attack_mode:
		return

	if just_changed_direction:
		return

	just_changed_direction = true
	var tween = create_tween()
	tween.tween_property(self, "position:y", global_position.y + 100, 0.2)

	direction *= -1

	await get_tree().create_timer(0.5).timeout
	just_changed_direction = false


func _on_behaviour_change() -> void:
	# Nur ausbrechen, wenn der Spawner wirklich einen Follow zugewiesen hat
	if randi_range(1, 12) == 1:
		if breakout_path_follow == null or not is_instance_valid(breakout_path_follow):
			push_warning("Breakout versucht, aber breakout_path_follow ist nicht gesetzt.")
			return

		attack_mode = true
