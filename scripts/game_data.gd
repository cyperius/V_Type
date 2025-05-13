extends Node

# Manche Notification-Konstanten wie `NOTIFICATION_ENTER_TREE`, `NOTIFICATION_READY` oder `EXIT_TREE`
# sind in Godot intern bereits im Node definiert – auch wenn sie im Editor nicht immer direkt sichtbar sind.
# `NOTIFICATION_RESIZED` hingegen ist nur in Control-Nodes verfügbar, daher definieren wir **diese eine Konstante manuell**.

# Warum wir nicht `extends Control` verwenden: 
# Weil dieses Script als Autoload (Singleton) im Hintergrund läuft und **nicht Teil der Benutzeroberfläche ist**.
# Control-Nodes sind speziell für UI gedacht und bringen zusätzliche Logik mit, die wir hier nicht brauchen.
# Um das Script so leichtgewichtig und unabhängig wie möglich zu halten, bleiben wir bei `extends Node`.

const NOTIFICATION_RESIZED = 40

var screen_size: Vector2
# Spielzustände
const STATE_MENU = "menu"
const STATE_PLAYING = "playing"
const STATE_PAUSED = "paused"
const STATE_GAME_OVER = "game_over"

var state: String = STATE_MENU  # Initialzustand


func _ready():
	screen_size = get_viewport().get_visible_rect().size
	# print("📐 Initiale Fenstergrösse:", screen_size)
	# print("GameData.gd bereit, aktueller Zustand:", state)

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		screen_size = get_viewport().get_visible_rect().size
		# print("📐 Fenstergrösse geändert:", screen_size)

# Optionale Helferfunktionen
func is_playing() -> bool:
	return state == STATE_PLAYING

func is_paused() -> bool:
	return state == STATE_PAUSED
