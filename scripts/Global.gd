extends Node

# Globale Referenz auf das Spieler-Schiff (z. B. für Kamera, UI, Gegner, GameManager etc.)
# Diese Variable wird vom Spieler-Script (player_ship.gd) im _ready() gesetzt
var player_ship = null

# Referenz auf den Sprite des Spieler-Schiffs (z. B. für Effekte, Animationen etc.)
# Wird ebenfalls im Spieler-Script gesetzt
var player_sprite = null

func _ready():
	# Wird beim Starten des Spiels einmalig aufgerufen.
	# Hier ist player_ship noch null, weil das Schiff noch nicht instanziiert wurde.
	print("Global.gd _ready aufgerufen. player_ship =", player_ship)
