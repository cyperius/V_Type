extends Node2D

signal boss_defeated
signal enemy_spawned(enemy: Node)
signal incoming_boss

@export var timer_basic_wait_time: int = 3
@export var timer2_basic_wait_time: int = 4

@export var level_boss: PackedScene
@export var basic_spawn_rate: int = 1

@export var enemy1: PackedScene
@export var enemy2_with_path: PackedScene
@export var enemy3: PackedScene
@export var enemy4_with_path: PackedScene
@export var enemy5: PackedScene
@export var enemy6_with_path: PackedScene
@export var enemy7: PackedScene
@export var enemy8_with_path: PackedScene

@onready var timer: Timer = $Timer
@onready var timer2: Timer = $Timer2
@onready var randomizer: RandomNumberGenerator = RandomNumberGenerator.new()

@onready var breakout_path_a: Path2D = get_parent().get_node("Paths/BreakoutPathA")
@onready var breakout_path_b: Path2D = get_parent().get_node("Paths/BreakoutPathB")

@onready var enemies_container: Node = get_parent().get_node("EnemiesContainer")
@onready var enemy_positions_node: Node = $SpawnPositions
@onready var enemy_positions: Array = enemy_positions_node.get_children()

@onready var enemy_counter: int = 0

var number_of_players: int
var spawn_rate: float
var boss_spawned: bool = false
var current_level: Node
var at_least_one_enemy_spawned: bool = false


func _ready() -> void:
	current_level = get_parent()
	number_of_players = 1
	set_spawn_rate()

	timer.timeout.connect(_on_timer_timeout)
	timer2.timeout.connect(_on_timer2_timeout)


func set_spawn_rate(spawn_rate: int = 1) -> void:
	spawn_rate = basic_spawn_rate
	number_of_players = Global.player_ships.size()

	spawn_rate = clamp(1, ((0.8 + GameManager.loop_counter / 5.0) * number_of_players * basic_spawn_rate), 4)

	timer.wait_time = timer_basic_wait_time / spawn_rate
	timer2.wait_time = timer2_basic_wait_time / spawn_rate

	print("spawn_rate = ", spawn_rate, " number_of_players = ", number_of_players)
	print("timer1 wait_time = ", timer.wait_time, " timer2 wait_time = ", timer2.wait_time)


func _assign_unique_breakout_follow(invader: Node, path_2d: Path2D) -> void:
	var follow: PathFollow2D = PathFollow2D.new()
	follow.loop = true

	# Optional: random Start ist ok, wird beim Breakout eh ueberschrieben
	follow.progress_ratio = randf()

	path_2d.add_child(follow)

	if invader.has_method("set_breakout_path_follow"):
		invader.set_breakout_path_follow(follow)
	else:
		push_warning("Invader hat keine set_breakout_path_follow()-Methode.")


func _process(delta: float) -> void:
	if at_least_one_enemy_spawned:
		if enemy_counter >= current_level.amount_of_enemies and boss_spawned == false:
			here_comes_the_boss()


func _on_timer_timeout() -> void:
	at_least_one_enemy_spawned = true

	for enemy_position in enemy_positions:
		var enemy = enemy1.instantiate()
		enemies_container.add_child(enemy)
		enemy.position = enemy_position.position
		enemy_counter += 1
	
		_assign_unique_breakout_follow(enemy, breakout_path_a)


func _on_timer2_timeout() -> void:
	pass


func here_comes_the_boss() -> void:
	if level_boss == null:
		emit_signal("boss_defeated")
	else:
		boss_spawned = true
		emit_signal("incoming_boss")
		enemy_counter += 1
		timer.stop()
		timer2.stop()
		var boss = level_boss.instantiate()
		get_tree().current_scene.add_child(boss)
		boss.connect("boss_defeated", Callable(self, "_on_boss_defeated"))
		boss.global_position = Vector2(7000, 1100)
		boss.health = boss.health * number_of_players


func _on_boss_defeated() -> void:
	emit_signal("boss_defeated")
