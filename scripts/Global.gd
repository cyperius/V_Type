extends Node

# Enthält Spieler-Schiff-Referenzen: {1: player1_ship, 2: player2_ship, ...}
var player_ships := {}

# enthält die aktuell 'toten' players
var destroyed_player_ships := []

# Enthält die jeweiligen Sprites der Spieler: {1: sprite1, 2: sprite2, ...}
var player_sprites := {}

func _ready():
	print("Global.gd _ready aufgerufen. Spieler-Daten:", player_ships)

# Helferfunktion, um ein Spieler-Schiff zu registrieren
func register_player(player_id: int, ship: Node, sprite: Node) -> void:
	player_ships[player_id] = ship
	player_sprites[player_id] = sprite
	print("✅ Spieler %d registriert" % player_id)

# Zugriffsfunktion für Schiffe
func get_player_ship(player_id: int) -> Node:
	return player_ships.get(player_id, null)

# Zugriffsfunktion für Sprite
func get_player_sprite(player_id: int) -> Node:
	return player_sprites.get(player_id, null)

# Helferfunktion, um die zerstörten Spieler-Schiffe zu erfassen
func register_player_destroyed(ship: Node) -> void:
	destroyed_player_ships.append(ship)
