extends Node2D

# Container in Main.tscn, in den Level geladen werden
@onready var level_container: Node = $LevelContainer
@onready var ui : Control = $UI
@onready var shop: Node2D = $Shop
@onready var start_menu: Node2D = $StartMenu
@onready var player_space_ship: Area2D = $player_space_ship
signal enemy_destroyed(score: int, energy: int)
var player_score = 0


func _ready() -> void:
	GameManager.state = GameManager.STATE_PLAYING
	# Main registriert seinen Container beim GameManager
	GameManager.register_level_container(level_container)
	# Erstes Level laden (GameManager.current_level ist ein int)
	GameManager._load_level(GameManager.current_level)
	enemy_destroyed.connect(_on_enemy_destroyed)
	
	
func _process(delta):
	if Input.is_action_just_pressed("level_1"):
		jump_to_level(1)
	if Input.is_action_just_pressed("level_2"):
		jump_to_level(2)
	if Input.is_action_just_pressed("level_3"):
		jump_to_level(3)
	if Input.is_action_just_pressed("level_4"):
		jump_to_level(4)
		
		
	
func jump_to_level(level_nr : int):
	await AudioManager.fade_out(4)
	GameManager._load_level(level_nr)	
	
	
func _on_enemy_destroyed(score, energy):
	print("signal angekommen")
	player_score += score
	ui.score.text = "Score: " + str(player_score)
