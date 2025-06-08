# Main.gd
extends Node2D

# Container in Main.tscn, in den Level geladen werden
@onready var level_container: Node = $LevelContainer

@onready var shop: Node2D = $Shop
@onready var start_menu: Node2D = $StartMenu
@onready var player_space_ship: Area2D = $player_space_ship


# Referenz auf das aktuell geladene Level
var current_level_node: Node = null

func _ready() -> void:
	GameManager.state = GameManager.STATE_PLAYING
	# Erstes Level laden (GameManager.current_level ist ein int)
	_load_level(GameManager.current_level)
	
	
func _process(delta):
	if Input.is_action_just_pressed("level_1"):
		jump_to_level(1)
	if Input.is_action_just_pressed("level_2"):
		jump_to_level(2)
	if Input.is_action_just_pressed("level_3"):
		jump_to_level(3)
	if Input.is_action_just_pressed("level_4"):
		jump_to_level(4)
		
	
func _load_level(level_nr: int) -> void:
	# Alten Level entfernen
	if current_level_node:
		current_level_node.queue_free()

	# Pfad aus Autoload holen (Array, 0-basiert)
	var path: String = GameManager.level_paths[level_nr - 1]

	# Szene dynamisch laden und als PackedScene casten
	var packed_scene := ResourceLoader.load(path) as PackedScene
	if not packed_scene:
		push_error("Konnte Level nicht laden: %s" % path)
		return

	# Instanziieren
	current_level_node = packed_scene.instantiate()

	# Persistente Daten übergeben, wenn das Level eine setup-Methode anbietet
	if current_level_node.has_method("setup"):
		current_level_node.setup(GameManager.score, GameManager.energy_units, GameManager.lives, GameManager.inventory)

	# In den Container einfügen
	level_container.add_child(current_level_node)

	# Signal fürs Level-Ende verbinden (Godot 4-Style)
	if current_level_node.has_signal("level_finished"):
		current_level_node.connect("level_finished", Callable(self, "_on_level_finished"))


func _on_level_finished(next_level_nr: int, gained_score: int = 0, gained_energy: int = 0) -> void:
	# Persistente Daten aktualisieren
	GameManager.score        += gained_score
	GameManager.energy_units += gained_energy
	GameManager.current_level = next_level_nr
	#AudioManager.fade_out(4)

	# Nächstes Level laden
	_load_level(GameManager.current_level)
	
	
func jump_to_level(level_nr : int):
	await AudioManager.fade_out(4)
	_load_level(level_nr)	
	
