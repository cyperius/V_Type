extends Node

# Pause-Mode Konstanten (Godot 4.4)
const PAUSE_MODE_INHERIT = 0
const PAUSE_MODE_STOP    = 1
const PAUSE_MODE_PROCESS = 2

signal connect_signals

# Manche Notification-Konstanten wie `NOTIFICATION_ENTER_TREE`, `NOTIFICATION_READY` oder `EXIT_TREE`
# sind in Godot intern bereits im Node definiert – auch wenn sie im Editor nicht immer direkt sichtbar sind.
# `NOTIFICATION_RESIZED` hingegen ist nur in Control-Nodes verfügbar, daher definieren wir **diese eine Konstante manuell**.
const NOTIFICATION_RESIZED = 40

var screen_size: Vector2

# Spielzustände
const STATE_MENU      = "menu"
const STATE_PLAYING   = "playing"
const STATE_PAUSED    = "paused"
const STATE_GAME_OVER = "game_over"

var state: String = STATE_MENU  # Initialzustand

# Persistente Daten
var score         : int        = 0
var inventory     : Dictionary = {}
var energy_units  : int        = 0
var lives         : int        = 3
var loop_counter  : float      = 1.0
# Aktuelles Level als Zahl
var current_level : int        = 1

# Reihenfolge der Level–Szenen
var level_paths   : Array      = [
	"res://scenes/levels/level_1.tscn",
	"res://scenes/levels/rigid_asteroid_level.tscn",
	"res://scenes/levels/level_3.tscn",
	# …weitere Levels hier anhängen
]

# Referenz auf den Container in Main, wird von Main übergeben
var level_container: Node = null

# Referenz auf das aktuell geladene Level
var current_level_node: Node = null

# GameOver-Szene (PackedScene) für spätere Instanziierung
var game_over_scene_packed: PackedScene = preload("res://scenes/game_over.tscn")

func _ready():
	screen_size = get_viewport().get_visible_rect().size
	# print("📐 Initiale Fenstergrösse:", screen_size)
	# print("GameManager bereit, aktueller Zustand:", state)

# Notification für Fenstergrößen-Änderung
func _notification(what):
	if what == NOTIFICATION_RESIZED:
		screen_size = get_viewport().get_visible_rect().size
		# print("📐 Fenstergrösse geändert:", screen_size)

# Helfer: Zustand prüfen
func is_playing() -> bool:
	return state == STATE_PLAYING

func is_paused() -> bool:
	return state == STATE_PAUSED

# Container übergeben
func register_level_container(container: Node) -> void:
	level_container = container

# Alle Gegner und Schüsse entfernen
func clear_level():
	get_tree().call_group("enemies", "queue_free")
	get_tree().call_group("projectiles", "queue_free")
	# get_tree().call_group("powerups", "queue_free")

# -------------------------
# State-Management + GameOver-Pause
# -------------------------

# Setzt alle persistenten Werte zurück und springt zurück auf Level 1
func reset_game_state() -> void:
	score = 0
	energy_units = 0
	lives = 3
	inventory.clear()
	current_level = 1
	

# Zentraler State-Wechsler
func set_state(new_state: String) -> void:
	state = new_state
	match state:
		STATE_PLAYING:
			get_tree().paused = false  # Spiel läuft weiter
		STATE_PAUSED:
			get_tree().paused = true   # Gesamt anhalten
		STATE_GAME_OVER:
			get_tree().paused = true   # Anhalten aller Nodes
			_start_game_over()

# Startet das GameOver: räumt auf, pausiert, zeigt Szene
func _start_game_over() -> void:
	clear_level()
	# Instanziere und füge die GameOver-Szene hinzu
	var game_over_scene: Node2D = game_over_scene_packed.instantiate() as Node2D
	game_over_scene.name = "GameOverScene"
	# Damit die GameOver-Szene auch im pausierten Baum weiterläuft
	# Damit die GameOver-Szene auch im pausierten Baum weiterläuft
	#game_over_scene.pause_mode = Node.PauseMode.PROCESS
	level_container.add_child(game_over_scene)
	# Verbindung zum Signal, wenn die Sequenz fertig ist
	if game_over_scene.has_signal("finished"):
		game_over_scene.connect("finished", Callable(self, "_on_game_over_finished"))

# Aufruf, wenn GameOver-Szene fertig ist
func _on_game_over_finished() -> void:
	if level_container.has_node("GameOverScene"):
		level_container.get_node("GameOverScene").queue_free()
	# Lade Main-Szene neu, Main._ready lädt aktuellen Level
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _load_level(level_nr: int) -> void:
	
	#instanziierte Objekte nach Typ entfernen (siehe clean_level() Funktion)
	clear_level()
	
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
	if current_level_node.has_signal("enemy_destroyed"):
		emit_signal("connect_signals")
		

func _on_level_finished(next_level_nr: int, gained_score: int = 0, gained_energy: int = 0) -> void:
	# Persistente Daten aktualisieren
	GameManager.score        += gained_score
	GameManager.energy_units += gained_energy
	GameManager.current_level = next_level_nr
	AudioManager.fade_out(4)

	# Nächstes Level laden
	_load_level(current_level)

# Für allfällige spätere Implementierung eines Shops / einer Werkstatt
# func next_state():
#	# Zwischen Level und Shop wechseln
#	if should_show_shop():
#		return "shop"
#	else:
#		return "level"

# func should_show_shop() -> bool:
#	# hier deine Logik, z.B. alle 3 Level
#	pass
