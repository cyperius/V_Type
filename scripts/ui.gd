extends Control

# Diese onready-Variablen bleiben wie gehabt
@onready var energy_labels := {}
@onready var destroyed_enemies_counter = $EnemiesDestroyed
@onready var score = $Score
@onready var health: Label = $Health
@onready var score_2: Label = $Score2
@onready var health_2: Label = $Health2
@onready var energy: Label = $energy

func _ready() -> void:
	var player_nr := 0

	for player in Global.player_ships:
		player_nr += 1

		# Laufzeit-Label erzeugen
		var label := Label.new()
		label.text = "Player%d Score" % player_nr
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
