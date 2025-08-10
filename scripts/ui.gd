extends Control

# Diese onready-Variablen bleiben wie gehabt
@onready var energy_labels := {}
@onready var destroyed_enemies_counter = $EnemiesDestroyed
@onready var score = $Score
@onready var health: Label = $Health
@onready var score_2: Label = $Score2
@onready var health_2: Label = $Health2
@onready var energy: Label = $energy

# Eine Zeile Text pro Spieler (Score, Energy, Health in einer Label-Zeile)
@onready var player_rows := {}  # player_id -> Label

# Sorgt dafür, dass für eine player_id ein Label existiert (lazy)
func _ensure_player_row(player_id: int) -> Label:
	# Falls schon vorhanden: zurückgeben
	if player_rows.has(player_id):
		return player_rows[player_id]

	# Neu anlegen
	var row := Label.new()
	row.name = "player_row_%d" % player_id
	# Sauber: Font-Größe via Theme-Override (ohne .ttf)
	row.add_theme_font_size_override("font_size", 28)

	# Feste Koordinaten (eine Zeile pro Spieler; 20px Start, 36px Zeilenhöhe)
	row.position = Vector2(20, 20 + (player_id - 1) * 36)

	add_child(row)
	player_rows[player_id] = row
	return row

# Öffentliche API für main.gd: eine Zeile updaten
func set_player_ui(pid: int, score: int, energy: int, health: int) -> void:
	var row := _ensure_player_row(pid)
	row.text = "P%d   Score: %d    Energy: %d    Health: %d" % [pid, score, energy, health]

# Optional: Gesamtzähler weiter darstellen (falls du das oben noch nutzt)
func set_destroyed_enemies(total: int) -> void:
	destroyed_enemies_counter.text = "Enemies destroyed: %d" % total


func _ready() -> void:
	var player_nr := 0

	for player in Global.player_ships:
		player_nr += 1

		# Laufzeit-Label erzeugen
		var label := Label.new()
		label.text = "Player%d Score: " % player_nr
		label.name = "score_player_%d" % player_nr

		# -> WICHTIG: Font-Größe ohne Font-Datei setzen
		# Godot 4: Theme-Override für die Schriftgröße (sauberer Weg)
		label.add_theme_font_size_override("font_size", 48)

		# Child einhängen
		add_child(label)

		# Harte Koordinaten relativ zum Parent (Control)
		label.position = Vector2(0, randi_range(0, 500))

	# Optional: vorhandene Labels ebenfalls größer machen
	for ui_label in [destroyed_enemies_counter, score, health, score_2, health_2, energy]:
		if ui_label:
			ui_label.add_theme_font_size_override("font_size", 48)
