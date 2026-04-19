extends Path2D

@onready var path: PathFollow2D = $PathFollow2D
@onready var enemy: Enemy = $PathFollow2D/Enemy1

var leave_path_ratio: float
var has_left_path := false

func _ready() -> void:
	path.set_progress_ratio(1)
	add_to_group("enemies")
	leave_path_ratio = randf_range(0.2, 0.6)
	enemy.tree_exiting.connect(queue_free)
	enemy.tree_exiting.connect(func(): print("Path2D wird jetzt gelöscht"))

func _process(delta: float) -> void:
	if has_left_path:
		return

	path.progress_ratio -= delta * 0.6 * GameManager.loop_counter

	if path.progress_ratio <= leave_path_ratio:
		has_left_path = true
		set_process(false)
		var fixed_ratio := path.progress_ratio
		path.set_process_mode(Node.PROCESS_MODE_DISABLED)
		path.progress_ratio = fixed_ratio  # einfrieren
		enemy.direction = Vector2(-1, 0)
		enemy.set_process(true)
				
