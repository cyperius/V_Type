extends Control

# ──────────────────────────────────────────────────────────────
#   REFERENCES
# ──────────────────────────────────────────────────────────────
var destroyed_enemies_counter: Label
var total_destroyed_enemies := 0


# Hält die HUD-Zeilen pro Spieler: player_id → Label
var player_rows: Dictionary = {}


# ──────────────────────────────────────────────────────────────
#   HELFER
# ──────────────────────────────────────────────────────────────
func _create_destroyed_enemies_counter() -> void:
	destroyed_enemies_counter = Label.new()
	destroyed_enemies_counter.name = "DestroyedEnemiesCounter"
	destroyed_enemies_counter.text = "Enemies destroyed: 00000"
	destroyed_enemies_counter.add_theme_font_size_override("font_size", 36)
	destroyed_enemies_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	add_child(destroyed_enemies_counter)

	destroyed_enemies_counter.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	destroyed_enemies_counter.offset_left = -480
	destroyed_enemies_counter.offset_top = 20
	destroyed_enemies_counter.offset_right = -40
	destroyed_enemies_counter.offset_bottom = 68


# Sorgt dafür, dass ein HUD-Label für einen Spieler existiert
func _ensure_player_row(player_id: int) -> Label:
	if player_rows.has(player_id):
		return player_rows[player_id]

	var row := Label.new()
	row.name = "player_row_%d" % player_id
	row.add_theme_font_size_override("font_size", 36)
	row.position = Vector2(20, 20 + (player_id - 1) * 48)
	add_child(row)

	player_rows[player_id] = row
	return row


# ──────────────────────────────────────────────────────────────
#   ÖFFENTLICHE API
# ──────────────────────────────────────────────────────────────
func set_player_ui(player_id: int, score: int, energy: int, health: int) -> void:
	var row := _ensure_player_row(player_id)
	row.text = "P%d   Score: %d    Energy: %d    Health: %d" % [player_id, score, energy, health]


func set_destroyed_enemies() -> void:
	print("ui: set_destroyed_enemies triggered")
	total_destroyed_enemies += 1
	if destroyed_enemies_counter != null:
		destroyed_enemies_counter.text = "Enemies destroyed: %d" % total_destroyed_enemies


# ──────────────────────────────────────────────────────────────
#   LEBENSZYKLUS
# ──────────────────────────────────────────────────────────────
func _ready() -> void:
	_create_destroyed_enemies_counter()

	GameManager.player_stats_changed.connect(set_player_ui)
	GameManager.enemy_destroyed.connect(set_destroyed_enemies)

	for player_id in Global.player_ships.keys():
		_ensure_player_row(player_id)
