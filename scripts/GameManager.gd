extends Node

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
var score         : int       = 0
var inventory     : Dictionary = {}
var energy_units  : int       = 0
var lives         : int       = 3

# Aktuelles Level als Zahl
var current_level : int       = 1

# Reihenfolge der Level–Szenen
var level_paths   : Array     = [
	"res://scenes/levels/level_1.tscn",
	"res://scenes/levels/rigid_asteroid_level.tscn",
	# …weitere Levels hier anhängen
]

# Für zukünftige Shop-Integration (momentan nicht genutzt)
# var shop_paths : Array = []

func _ready():
	screen_size = get_viewport().get_visible_rect().size
	# print("📐 Initiale Fenstergrösse:", screen_size)
	# print("GameManager bereit, aktueller Zustand:", state)

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		screen_size = get_viewport().get_visible_rect().size
		# print("📐 Fenstergrösse geändert:", screen_size)

# Optionale Helferfunktionen
func is_playing() -> bool:
	return state == STATE_PLAYING

func is_paused() -> bool:
	return state == STATE_PAUSED

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

