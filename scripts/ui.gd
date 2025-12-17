extends Control

# ──────────────────────────────────────────────────────────────
#   REFERENCES
# ──────────────────────────────────────────────────────────────
@onready var destroyed_enemies_counter: Label = $EnemiesDestroyed


# Hält die HUD-Zeilen pro Spieler: player_id → Label
var player_rows: Dictionary = {}





# ──────────────────────────────────────────────────────────────
#   HELFER
# ──────────────────────────────────────────────────────────────
# Sorgt dafür, dass ein HUD-Label für einen Spieler existiert
func _ensure_player_row(player_id: int) -> Label:
	if player_rows.has(player_id):
		return player_rows[player_id]

	var row := Label.new()
	row.name = "player_row_%d" % player_id
	row.add_theme_font_size_override("font_size", 28)
	row.position = Vector2(20, 20 + (player_id - 1) * 36)
	add_child(row)

	player_rows[player_id] = row
	return row


# ──────────────────────────────────────────────────────────────
#   ÖFFENTLICHE API
# ──────────────────────────────────────────────────────────────

# wird via Signal vom GameManager aufgerufen werden
func set_player_ui(player_id: int, score: int, energy: int, health: int) -> void:
	var row := _ensure_player_row(player_id)
	# print("set_player_ui for player: ", player_id)
	row.text = "P%d   Score: %d    Energy: %d    Health: %d" % [player_id, score, energy, health]

# Globalen Gegnerzähler setzen
func set_destroyed_enemies(total: int) -> void:
	if destroyed_enemies_counter:
		destroyed_enemies_counter.text = "Enemies destroyed: %d" % total


# ──────────────────────────────────────────────────────────────
#   LEBENSZYKLUS
# ──────────────────────────────────────────────────────────────
func _ready() -> void:
	
	GameManager.player_stats_changed.connect(set_player_ui)
	
	# Vorhandene Spieler bei Spielstart initialisieren
	for player_id in Global.player_ships.keys():
		_ensure_player_row(player_id)

	# Gegnerzähler initial groß setzen
	if destroyed_enemies_counter:
		destroyed_enemies_counter.add_theme_font_size_override("font_size", 28)
