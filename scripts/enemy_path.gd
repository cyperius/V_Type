extends Path2D

signal enemy_deleted
signal enemy_spawned

@onready var path : PathFollow2D = $PathFollow2D
@onready var enemy_on_path = $PathFollow2D/Mech_Enemy


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	enemy_spawned.connect(func(): GameManager._on_enemy_spawned())
	enemy_spawned.emit()
	path.set_progress_ratio(1)
	add_to_group("enemies")
	enemy_deleted.connect(GameManager._on_enemy_deleted)
	# Sicherstellen dass es die Variable beim abgehängten Feind gibt...
	if "path2d_origin" in enemy_on_path: # und in diesem Fall...
		enemy_on_path.path2d_origin = true # Boolean auf true setzen
		enemy_on_path.death_module.path_node_to_delete = self # übergibt sich 
		# selbst als Referenz dem enemy der dem Pfad folgt (bzw. dessen death_module) 
		
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	path.progress_ratio -= delta * 0.1 * GameManager.loop_counter
	if path.progress_ratio <= 0:
		emit_signal("enemy_deleted")
		queue_free()
		
		
func _on_following_path_enemy_destroyed() -> void:
	await get_tree().create_timer(0.5).timeout
	#print("enemy_with_path: lösche Pfad")
	queue_free()
		
