extends Node2D

signal enemy_destroyed(score: int, energy: int)
signal absorbed_energy(amount)

@onready var level_container: Node   = $LevelContainer
@onready var ui              : Control = $UI
@onready var shop            : Node2D  = $Shop
@onready var start_menu      : Node2D  = $StartMenu
@onready var player          : Area2D  = $player_space_ship

var player_score               = 0
var destroyed_enemies_counter  = 0

func _ready() -> void:
	GameManager.connect_signals.connect(_on_connect_the_signals)
	# Hier setzen wir wieder auf Playing und registrieren Container
	GameManager.set_state(GameManager.STATE_PLAYING)
	GameManager.register_level_container(level_container)
	# Level neu laden anhand current_level
	GameManager._load_level(GameManager.current_level)

	ui.destroyed_enemies_counter.text = "Enemies destroyed: " + str(destroyed_enemies_counter)
	ui.score.text                    = "Score: " + str(player_score)
	ui.energy.text                   = "Energy: " + str(player.blue_energy)
	ui.health.text = "Health: " + str(player.health)
	if level_container.get_child_count() > 0:
		var current_level_node = level_container.get_child(0)
		if current_level_node.has_signal("enemy_destroyed"):
			current_level_node.enemy_destroyed.connect(_on_enemy_destroyed)
		if current_level_node.has_signal("level_finished"):
			current_level_node.level_finished.connect(_on_level_finished)

func _process(delta):
	if Input.is_action_just_pressed("level_1"):
		jump_to_level(1)
	if Input.is_action_just_pressed("level_2"):
		jump_to_level(2)
	if Input.is_action_just_pressed("level_3"):
		jump_to_level(3)
	if Input.is_action_just_pressed("level_4"):
		jump_to_level(4)

func jump_to_level(level_nr: int) -> void:
	await AudioManager.fade_out(4)
	GameManager.current_level = level_nr
	GameManager._load_level(level_nr)

func _on_enemy_destroyed(score: int, energy: int) -> void:
	player_score += score
	ui.score.text = "Score: " + str(player_score)
	destroyed_enemies_counter += 1
	ui.destroyed_enemies_counter.text = "Enemies destroyed: " + str(destroyed_enemies_counter)

func _on_level_finished(next_level_nr: int, gained_score: int = 0, gained_energy: int = 0) -> void:
	pass
	# Hier ggf. nichts oder Logging — Level-Wechsel übernimmt GameManager

func _on_connect_the_signals() -> void:
	GameManager.current_level_node.enemy_destroyed.connect(_on_enemy_destroyed)
