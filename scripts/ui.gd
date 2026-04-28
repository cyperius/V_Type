extends Control

# ──────────────────────────────────────────────────────────────
#   REFERENZEN AUF UI-NODES, DIE BEREITS IN DER SZENE EXISTIEREN
# ──────────────────────────────────────────────────────────────
# Dieser GridContainer liegt laut deinem Szenenbaum unter:
# UI -> MarginContainer -> GridContainer
# In ihn fügen wir die Counter-Labels ein.
@onready var grid_container: GridContainer = $MarginContainer/GridContainer


# ──────────────────────────────────────────────────────────────
#   REFERENZEN AUF DIE PER CODE ERZEUGTEN LABELS
# ──────────────────────────────────────────────────────────────
# Wir trennen jetzt jeweils Titel und Zahlenwert in zwei eigene Labels.
# Dadurch kann der GridContainer sie sauber in 2 Spalten anordnen:
# links die Titel, rechts die Zahlen.
var spawned_enemies_title_label: Label
var spawned_enemies_value_label: Label
var destroyed_enemies_title_label: Label
var destroyed_enemies_value_label: Label
var deleted_enemies_title_label: Label
var deleted_enemies_value_label: Label


# Gesamtzahl zerstörter Gegner.
var total_destroyed_enemies: int = 0

# Gesamtzahl gespawnter Gegner
var total_spawned_enemies: int = 0

# Gesamtzahl gelöschter Gegner
var total_deleted_enemies: int = 0





# Hält die HUD-Zeilen pro Spieler:
# player_id -> Label
# Diese Labels bleiben in diesem Beispiel weiterhin frei im UI,
# also NICHT im GridContainer, damit dein bestehendes Layout nicht
# ungewollt zerstört wird.
var player_rows: Dictionary = {}


# ──────────────────────────────────────────────────────────────
#   HELFER FÜR EINHEITLICHE LABEL-ERSTELLUNG
# ──────────────────────────────────────────────────────────────
# Diese Funktion baut ein neues Label mit einheitlicher Schriftgröße
# und gewünschter Ausrichtung.
func _create_label(label_name: String, label_text: String, alignment: HorizontalAlignment) -> Label:
	var new_label := Label.new()
	new_label.name = label_name
	new_label.text = label_text
	new_label.add_theme_font_size_override("font_size", 36)
	new_label.horizontal_alignment = alignment
	return new_label


# ──────────────────────────────────────────────────────────────
#   ERZEUGT DIE BEIDEN COUNTER-ZEILEN IM GRIDCONTAINER
# ──────────────────────────────────────────────────────────────
# Der GridContainer bekommt 2 Spalten:
# Spalte 1 = Titel
# Spalte 2 = Zahlenwert
#
# Wichtig:
# Hier setzen wir KEINE Anchors und KEINE Offsets auf den Labels,
# weil der GridContainer das Layout selbst übernimmt.
func _create_enemy_counter_labels() -> void:
	# Sicherheitshalber auf 2 Spalten setzen.
	# Damit werden die Kinder zeilenweise so angeordnet:
	# [Titel 1] [Wert 1]
	# [Titel 2] [Wert 2]
	grid_container.columns = 2

	# Falls du die Szene neu lädst oder _ready mehrfach in Tests aufrufst,
	# verhindern wir doppelte Labels.
	for child in grid_container.get_children():
		child.queue_free()

	# Titel links, Wert rechts.
	spawned_enemies_title_label = _create_label(
		"SpawnedEnemiesTitleLabel",
		"Spawned Enemies:",
		HORIZONTAL_ALIGNMENT_LEFT
	)

	spawned_enemies_value_label = _create_label(
		"SpawnedEnemiesValueLabel",
		"00000",
		HORIZONTAL_ALIGNMENT_RIGHT
	)

	destroyed_enemies_title_label = _create_label(
		"DestroyedEnemiesTitleLabel",
		"Enemies destroyed: ",
		HORIZONTAL_ALIGNMENT_LEFT
	)

	destroyed_enemies_value_label = _create_label(
		"DestroyedEnemiesValueLabel",
		"00000",
		HORIZONTAL_ALIGNMENT_RIGHT
	)
	
	deleted_enemies_title_label = _create_label(
		"DeletedEnemiesTitleLabel",
		"Enemies deleted:",
		HORIZONTAL_ALIGNMENT_LEFT
	)

	deleted_enemies_value_label = _create_label(
		"DeletedEnemiesValueLabel",
		"00000",
		HORIZONTAL_ALIGNMENT_RIGHT
	)

	# Dem GridContainer hinzufügen.
	# Reihenfolge ist wichtig, weil der GridContainer danach die Zellen füllt.
	grid_container.add_child(spawned_enemies_title_label)
	grid_container.add_child(spawned_enemies_value_label)
	grid_container.add_child(destroyed_enemies_title_label)
	grid_container.add_child(destroyed_enemies_value_label)
	grid_container.add_child(deleted_enemies_title_label)
	grid_container.add_child(deleted_enemies_value_label)


# ──────────────────────────────────────────────────────────────
#   SPIELER-ZEILEN ERZEUGEN
# ──────────────────────────────────────────────────────────────
# Diese Funktion sorgt dafür, dass pro Spieler genau ein Label existiert.
# Anders als die Enemy-Counter landen diese Labels hier weiterhin direkt
# unter dem UI-Control und nicht im GridContainer.
#
# Warum?
# Weil dein aktueller GridContainer für das 2-Spalten-Layout der Counter
# gedacht ist. Würden wir die Spielerzeilen auch dort einfügen, würden sie
# in das gleiche Raster gezwungen und wahrscheinlich komisch aussehen.
func _ensure_player_row(player_id: int) -> Label:
	if player_rows.has(player_id):
		return player_rows[player_id]

	var player_row := Label.new()
	player_row.name = "PlayerRow%d" % player_id
	player_row.add_theme_font_size_override("font_size", 36)

	# Diese Labels werden weiterhin frei positioniert.
	# Wenn du später auch dafür einen eigenen VBoxContainer willst,
	# kann man das noch sauberer umbauen.
	player_row.position = Vector2(20, 20 + (player_id - 1) * 48)

	add_child(player_row)

	player_rows[player_id] = player_row
	return player_row


# ──────────────────────────────────────────────────────────────
#   FORMATIERUNGS-HELFER
# ──────────────────────────────────────────────────────────────
# Formatiert Zahlen immer als 5-stellige Anzeige mit führenden Nullen.
# Beispiel:
# 0   -> 00000
# 12  -> 00012
# 314 -> 00314
func _format_counter_value(value: int) -> String:
	return str(value).pad_zeros(5)


# ──────────────────────────────────────────────────────────────
#   ÖFFENTLICHE API FÜR SPIELER-ANZEIGE
# ──────────────────────────────────────────────────────────────
# Aktualisiert die HUD-Zeile eines Spielers.
func set_player_ui(player_id: int, score: int, energy: int, health: int) -> void:
	var player_row := _ensure_player_row(player_id)
	player_row.text = "P%d   Score: %d    Energy: %d    Health: %d" % [
		player_id,
		score,
		energy,
		health
	]


# ──────────────────────────────────────────────────────────────
#   ÖFFENTLICHE API FÜR ENEMY-COUNTER
# ──────────────────────────────────────────────────────────────
# Wird aufgerufen, wenn ein Gegner zerstört wurde.
# Erhöht den Zähler und aktualisiert nur das Wert-Label,
# nicht den kompletten Text wie vorher.
func set_destroyed_enemies() -> void:
	print("ui: set_destroyed_enemies triggered")

	total_destroyed_enemies += 1

	if destroyed_enemies_value_label != null:
		destroyed_enemies_value_label.text = _format_counter_value(total_destroyed_enemies)


# Optional:
# Falls du irgendwo auch die gespawnten Gegner mitzählen willst,
# kannst du diese Funktion nutzen.
func set_spawned_enemies(value: int) -> void:
	total_spawned_enemies = value

	if spawned_enemies_value_label != null:
		spawned_enemies_value_label.text = _format_counter_value(total_spawned_enemies)


# Optional:
# Falls du lieber bei jedem Spawn einfach hochzählen willst. -> aktuell 23.4.26 verwendet
func increase_spawned_enemies() -> void:
	total_spawned_enemies += 1

	if spawned_enemies_value_label != null:
		spawned_enemies_value_label.text = _format_counter_value(total_spawned_enemies)
		
func increase_deleted_enemies() -> void:
	total_deleted_enemies += 1

	if deleted_enemies_value_label != null:
		deleted_enemies_value_label.text = _format_counter_value(total_deleted_enemies)


# ──────────────────────────────────────────────────────────────
#   LEBENSZYKLUS
# ──────────────────────────────────────────────────────────────
func _ready() -> void:
	# Baut die 4 Labels für die zwei Counter-Zeilen.
	_create_enemy_counter_labels()

	# Verbindungen zu deinen Signalen.
	# Diese bleiben grundsätzlich wie vorher.
	GameManager.player_stats_changed.connect(set_player_ui)
	GameManager.enemy_destroyed.connect(set_destroyed_enemies)
	GameManager.enemy_spawned.connect(increase_spawned_enemies)
	GameManager.enemy_deleted.connect(increase_deleted_enemies)

	# Falls du ein Signal für gespawnte Enemies hast, könntest du zusätzlich
	# z. B. so verbinden:
	# GameManager.enemy_spawned.connect(increase_spawned_enemies)

	# Für schon vorhandene Spieler beim Start die Zeilen anlegen.
	for player_id in Global.player_ships.keys():
		_ensure_player_row(player_id)

	# Startwerte explizit setzen, damit die Anzeige beim Start sicher stimmt.
	if spawned_enemies_value_label != null:
		spawned_enemies_value_label.text = _format_counter_value(total_spawned_enemies)

	if destroyed_enemies_value_label != null:
		destroyed_enemies_value_label.text = _format_counter_value(total_destroyed_enemies)
