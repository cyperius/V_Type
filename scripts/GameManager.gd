extends Node

signal connect_signals

const NOTIFICATION_RESIZED = 40

var screen_size: Vector2

const STATE_MENU = "menu"
const STATE_PLAYING = "playing"
const STATE_PAUSED = "paused"
const STATE_GAME_OVER = "game_over"

var state: String = STATE_MENU

var score: int = 0
var inventory: Dictionary = {}
var energy_units: int = 0
var lives: int = 3
var loop_counter: float = 1.0
var current_level: int = 1

var level_paths: Array = [
	"res://scenes/levels/level_1.tscn",
	"res://scenes/levels/rigid_asteroid_level.tscn",
	"res://scenes/levels/level_3.tscn",
]

var level_container: Node = null
var current_level_node: Node = null
var game_over_scene_packed: PackedScene = preload("res://scenes/game_over.tscn")

func _ready():
	screen_size = get_viewport().get_visible_rect().size

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		screen_size = get_viewport().get_visible_rect().size

func is_playing() -> bool:
	return state == STATE_PLAYING

func is_paused() -> bool:
	return state == STATE_PAUSED

func register_level_container(container: Node) -> void:
	level_container = container

func clear_level() -> void:
	get_tree().call_group("enemies", "queue_free")
	get_tree().call_group("projectiles", "queue_free")

func reset_game_state() -> void:
	score = 0
	energy_units = 0
	lives = 3
	inventory.clear()
	current_level = 1

func set_state(new_state: String) -> void:
	state = new_state
	match state:
		STATE_PLAYING:
			get_tree().paused = false
		STATE_PAUSED:
			get_tree().paused = true
		STATE_GAME_OVER:
			get_tree().paused = true
			_start_game_over()

func _start_game_over() -> void:
	clear_level()
	if level_container:
		var game_over_scene: Node2D = game_over_scene_packed.instantiate() as Node2D
		game_over_scene.name = "GameOverScene"
		#game_over_scene.pause_mode = Node.PAUSE_MODE_PROCESS
		level_container.add_child(game_over_scene)
		if game_over_scene.has_signal("finished"):
			game_over_scene.connect("finished", Callable(self, "_on_game_over_finished"))

func _on_game_over_finished() -> void:
	if level_container.has_node("GameOverScene"):
		level_container.get_node("GameOverScene").queue_free()
	reset_game_state()
	state = STATE_PLAYING
	get_tree().paused = false
	GameManager._load_level(current_level)

func _load_level(level_nr: int) -> void:
	clear_level()
	if current_level_node:
		current_level_node.queue_free()
	var path: String = level_paths[level_nr - 1]
	var packed_scene := ResourceLoader.load(path) as PackedScene
	if not packed_scene:
		push_error("Konnte Level nicht laden: %s" % path)
		return
	current_level_node = packed_scene.instantiate()
	if current_level_node.has_method("setup"):
		current_level_node.setup(score, energy_units, lives, inventory)
	level_container.add_child(current_level_node)
	if current_level_node.has_signal("level_finished"):
		current_level_node.connect("level_finished", Callable(self, "_on_level_finished"))
	if current_level_node.has_signal("enemy_destroyed"):
		emit_signal("connect_signals")

func _on_level_finished(next_level_nr: int, gained_score: int = 0, gained_energy: int = 0) -> void:
	score += gained_score
	energy_units += gained_energy
	current_level = next_level_nr
	AudioManager.fade_out(4)
	GameManager._load_level(current_level)
