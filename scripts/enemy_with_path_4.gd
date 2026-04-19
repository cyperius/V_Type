extends Path2D

signal enemy_destroyed(score: int, energy: int)

@onready var path : PathFollow2D = $PathFollow2D
@onready var zombee = %Zombee
@onready var timer: Timer = $Timer


# Called when the node enters the scene tree for the first tim>e.
func _ready() -> void:
	path.set_progress_ratio(1)
	add_to_group("enemies")
	enemy_destroyed.connect(_on_enemy_destroyed)
	#mech_enemy.set_skin2()
	zombee.scale = Vector2(0.1, 0.1)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	path.progress_ratio -= delta * 0.06 * GameManager.loop_counter
	if path.progress_ratio <= 0:
		queue_free()

func _on_enemy_destroyed(score: int, energy: int) -> void:
	emit_signal("enemy_destroyed", score, energy)
