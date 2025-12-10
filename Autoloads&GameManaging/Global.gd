extends Node

# ──────────────────────────────────────────────────────────────
#   SIGNALS
# ──────────────────────────────────────────────────────────────
## Wird gesendet, wenn ein Spieler registriert (beigetreten) wurde.
signal player_registered(player_id: int)
## Wird gesendet, wenn ein Spieler deregistriert (verlassen) wurde.
signal player_unregistered(player_id: int)
## Wird gesendet, wenn ein Spieler neu zerstört wurde.
signal player_destroyed(player_id: int)
## Wird gesendet, wenn ein Spieler wieder aktiv/belebt ist (Respawn/Revive).
signal player_revived(player_id: int)
## Wird gesendet, sobald sich die Gesamtlage der Spieler ändert
## (Join/Leave/Destroyed/Revived) → gut für UI/Logik, die auf „Roster“-Änderungen hört.
signal roster_changed()

# ──────────────────────────────────────────────────────────────
#   SPIELER-DATEN
# ──────────────────────────────────────────────────────────────
## Enthält Spieler-Schiff-Referenzen: {1: player1_ship, 2: player2_ship, ...}
var player_ships: Dictionary[int, Node] = {}

## Enthält die jeweiligen Sprites der Spieler: {1: sprite1, 2: sprite2, ...}
var player_sprites: Dictionary[int, Node] = {}

## „Set“ der zerstörten Spieler (als Dictionary realisiert): { player_id: true, ... }
## Vorteil: O(1)-Nachschauen, garantiert eindeutige Einträge, robust bei queue_free().
var destroyed_player_ids: Dictionary[int, bool] = {}

# ──────────────────────────────────────────────────────────────
#   LEBENSZYKLUS
# ──────────────────────────────────────────────────────────────
func _ready() -> void:
	print("🌍 Global.gd _ready – Spieler-Daten:", player_ships)

# ──────────────────────────────────────────────────────────────
#   REGISTRIERUNG / DEREGISTRIERUNG
# ──────────────────────────────────────────────────────────────
func register_player(player_id: int, ship: Node, sprite: Node) -> void:
	# Spieler beitreten lassen oder Eintrag aktualisieren
	player_ships[player_id] = ship
	player_sprites[player_id] = sprite
	# Falls diese ID zuvor als „zerstört“ markiert war, beim Beitritt/Respawn
	# aus der zerstörten-Menge entfernen (lebt jetzt wieder)
	if destroyed_player_ids.has(player_id):
		destroyed_player_ids.erase(player_id)
		emit_signal("player_revived", player_id)
	# Events für Außenwelt
	emit_signal("player_registered", player_id)
	emit_signal("roster_changed")
	print("✅ Spieler %d registriert" % player_id)
	print(player_ships.size())

func unregister_player(player_id: int) -> void:
	# Spieler verlässt das Level/Spielerpool
	if player_ships.has(player_id):
		player_ships.erase(player_id)
	if player_sprites.has(player_id):
		player_sprites.erase(player_id)
	# Sicherstellen, dass er nicht mehr als zerstört gezählt wird
	if destroyed_player_ids.has(player_id):
		destroyed_player_ids.erase(player_id)
	# Events
	emit_signal("player_unregistered", player_id)
	emit_signal("roster_changed")
	print("🗑️ Spieler %d deregistriert" % player_id)

# ──────────────────────────────────────────────────────────────
#   ZERSTÖRUNG / REVIVE
# ──────────────────────────────────────────────────────────────
func mark_player_destroyed(player_id: int) -> void:
	# Nur hinzufügen, wenn noch nicht als zerstört markiert
	if destroyed_player_ids.has(player_id):
		return
	destroyed_player_ids[player_id] = true
	#player_ships.erase(player_id)  # Habe ich neu eingefügt 1.12.2025
	emit_signal("player_destroyed", player_id)
	emit_signal("roster_changed")
	print("💥 Spieler %d zerstört" % player_id)

func revive_player(player_id: int) -> void:
	# Entfernt die ID aus der Zerstört-Menge, wenn vorhanden
	if destroyed_player_ids.erase(player_id):
		emit_signal("player_revived", player_id)
		emit_signal("roster_changed")
		print("🔁 Spieler %d wieder aktiv" % player_id)

# ──────────────────────────────────────────────────────────────
#   ZUGRIFFSFUNKTIONEN
# ──────────────────────────────────────────────────────────────
func get_player_ship(player_id: int) -> Node:
	var ship : Node = player_ships.get(player_id, null)
	if ship != null and !is_instance_valid(ship):
		# Hängende Referenz sofort aus dem Dictionary entfernen
		player_ships.erase(player_id)
		# (optional) zugehörigen Sprite-Eintrag ebenfalls säubern
		if player_sprites.has(player_id):
			player_sprites.erase(player_id)
		return null
	return ship

func clear_all_player_data() -> void:
	# Existierende Schiffe sicher freigeben
	for player_id in player_ships.keys():
		var ship := player_ships[player_id]
		if is_instance_valid(ship):
			ship.queue_free()
	# Dictionaries komplett leeren
	player_ships.clear()
	player_sprites.clear()
	destroyed_player_ids.clear()
	emit_signal("roster_changed")

func get_player_sprite(player_id: int) -> Node:
	return player_sprites.get(player_id, null)

func is_destryed(player_id: int) -> bool:
	return destroyed_player_ids.has(player_id)

func get_total_players() -> int:
	return player_ships.size()

func get_destroyed_count() -> int:
	return destroyed_player_ids.size()

func get_alive_player_ids() -> Array[int]:
	var result: Array[int] = []
	for player_id in player_ships.keys():
		if !destroyed_player_ids.has(player_id):
			result.append(player_id)
	return result

## Zentrale Game-Over-Bedingung: robust gegenüber dynamischem Join/Leave.
func should_game_over() -> bool:
	var total_players := get_total_players() # zählt alle Spieler, die im aktuellen Spiel mitgespielt haben
	if total_players <= 0:
		# Keine aktiven Spieler → kein Game Over erzwingen (oder abhängig von deiner Design-Entscheidung)
		return false
	return get_destroyed_count() >= total_players # gleich viele (oder mehr) Spieler zerstört als mitgespielt haben? gibt true oder false zurück

# ──────────────────────────────────────────────────────────────
#   RUNDE / LEVELSTART
# ──────────────────────────────────────────────────────────────
func reset_round_state() -> void:
	# Am Levelstart aufrufen: leert die zerstörten IDs.
	destroyed_player_ids.clear()
	emit_signal("roster_changed")
	print("🔄 Global: Rundenzustand zurückgesetzt")
