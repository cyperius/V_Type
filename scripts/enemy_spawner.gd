extends Node2D

@onready var timer = $Timer
#@onready var timer2 = $Timer2
@onready var randomizer = RandomNumberGenerator.new()
@onready var enemy_blueprint = preload("res://scenes/enemy_1.tscn")
#@onready var enemy_with_path_blueprint = preload("")

@onready var enemy_positions_node = $SpawnPositions
@onready var enemy_positions = enemy_positions_node.get_children()
# so erhält man einen array, mit den child_nodes des Node Spawn-positions 
# (welcher hier der Variable enemy_positions_node zugewiesen ist)


func _ready() -> void:
	timer.timeout.connect(_on_timer_timeout)



func _on_timer_timeout():
	var spawn_pos_nr = randi_range(0, 5)
	var enemy = enemy_blueprint.instantiate()
	get_tree().current_scene.add_child(enemy)
	enemy.position = enemy_positions[spawn_pos_nr].position
	#print(enemy.global_position)
