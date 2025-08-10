extends Node2D

## Signale vom Level (Erwartung: Level sendet auch player_id mit)
## Falls dein Level aktuell (score, energy) ohne player_id sendet:
## -> Siehe Kommentar in _connect_level_signals().
signal enemy_destroyed(score: int, energy: int, player_id: int)
signal absorbed_energy(amount: int, player_id: int)

## Spielstände / Zähler
var total_destroyed_enemies: int = 0
var player_scores := {}             # Dictionary: player_id -> score (int)

## Bequeme Referenzen
@onready var level_container: Node  = $LevelContainer
@onready var ui              : Control = $UI
@onready var shop            : Node2D  = $Shop
@onready var start_menu      : Node2D  = $StartMenu

func _ready() -> void:
	# Initialisiere Scores für alle aktiven Spieler
	for player_id in Global.player_ships.keys():
		player_scores[player_id] = 0

	# Spielzustand setzen und Level laden/registrieren
	GameManager.connect_signals.connect(_on_connect_the_signals)
	GameManager.set_state(GameManager.STATE_PLAYING)
	GameManager.register_level_container(level_container)
	GameManager._load_level(GameManager.current_level)

	# Direkt nach dem Laden: aktuelle Level-Node greifen und Signale verbinden
	_connect_level_signals()

	# Erste UI-Synchronisation (global + pro Spieler)
	_update_global_ui()
	_update_all_players_ui()

	# Debug-Ausgabe (hilft beim Umstieg auf Multi-Player)
	print("Active players: ", Global.player_ships.size(), \
		  " | Destroyed players: ", Global.destroyed_player_ships.size())


func _process(delta: float) -> void:
	# Debug-Hotkeys zum Springen zwischen Levels (optional beibehalten)
	if Input.is_action_just_pressed("level_1"):
		_jump_to_level(1)
	if Input.is_action_just_pressed("level_2"):
		_jump_to_level(2)
	if Input.is_action_just_pressed("level_3"):
		_jump_to_level(3)
	if Input.is_action_just_pressed("level_4"):
		_jump_to_level(4)


# ---------------------------
# Level-Handling
# ---------------------------

func _jump_to_level(level_number: int) -> void:
	await AudioManager.fade_out(4)
	GameManager.current_level = level_number
	GameManager._load_level(level_number)
	_connect_level_signals()      # Nach jedem Load neu verbinden
	_reset_runtime_counters_for_new_level()
	_update_global_ui()
	_update_all_players_ui()


func _connect_level_signals() -> void:
	if level_container.get_child_count() == 0:
		return
	var current_level: Node = level_container.get_child(0)

	# Sicher verbinden, wenn vorhanden
	if current_level.has_signal("enemy_destroyed"):
		# Erwartete Signatur: enemy_destroyed(score:int, energy:int, player_id:int)
		# FALLBACK: Wenn dein Level noch KEINE player_id mitsendet,
		# 1) passe dort die Signal-Emission an ODER
		# 2) ent-kommentiere die alternative Verbindung und nimm player_id=1 an.
		current_level.enemy_destroyed.connect(_on_enemy_destroyed)

		# Alternative (Fallback ohne player_id):
		# current_level.enemy_destroyed.connect(func(score:int, energy:int):
		# 	_on_enemy_destroyed(score, energy, 1)  # Default: Spieler 1
		# )

	if current_level.has_signal("level_finished"):
		current_level.level_finished.connect(_on_level_finished)


func _reset_runtime_counters_for_new_level() -> void:
	# Wenn du pro Level zurücksetzen willst, mach es hier.
	# Beispiel: total_destroyed_enemies = 0
	# player_scores.clear()  # Nur falls Levelwechsel Score neu starten soll
	pass


# ---------------------------
# Signal-Callbacks
# ---------------------------

func _on_enemy_destroyed(score: int, energy: int, player_id: int) -> void:
	# 1) Gesamtkillzähler
	total_destroyed_enemies += 1

	# 2) Score des verursachenden Spielers
	if not player_scores.has(player_id):
		player_scores[player_id] = 0
	player_scores[player_id] += score

	# 3) Spieler-Energie hochzählen (sofern du das willst)
	#    Wir gehen davon aus: Global.player_ships[player_id] existiert und hat z. B. blue_energy
	if Global.player_ships.has(player_id) and Global.player_ships[player_id].has_variable("blue_energy"):
		Global.player_ships[player_id].blue_energy += energy

	# 4) UI aktualisieren: global + nur der betroffene Spieler schnell
	_update_global_ui()
	_update_player_ui(player_id)


func _on_level_finished(next_level_number: int, gained_score: int = 0, gained_energy: int = 0) -> void:
	# Hier ggf. Logging, Highscore, etc. – Levelwechsel übernimmt GameManager
	pass


func _on_connect_the_signals() -> void:
	# Wird von GameManager.connect_signals ausgelöst – sichere Neuverkabelung
	if GameManager.current_level_node and GameManager.current_level_node.has_signal("enemy_destroyed"):
		GameManager.current_level_node.enemy_destroyed.connect(_on_enemy_destroyed)
		
# ---------------------------
# UI‑Hilfsfunktionen
# ---------------------------

func _update_global_ui() -> void:
	# Globaler Counter (falls im UI vorhanden)
	if ui and ui.destroyed_enemies_counter:
		ui.destroyed_enemies_counter.text = "Enemies destroyed: %d" % total_destroyed_enemies


func _update_all_players_ui() -> void:
	for player_id in Global.player_ships.keys():
		_update_player_ui(player_id)


func _update_player_ui(player_id: int) -> void:
	if not ui:
		return

	# SCORE
	var score_label_path := "score_player_%d" % player_id
	var score_label := ui.get_node_or_null(score_label_path)
	if score_label:
		var score_count : int = player_scores.get(player_id, 0)
		score_label.text = "Score (P%d): %d" % [player_id, score_count]

	# ENERGY (optional – nur wenn du Energie-Labels pro Spieler angelegt hast)
	# Erwartete Namen, falls du sie so benennst wie beim Score:
	#   energy_player_1, energy_player_2, ...
	var energy_label_path := "energy_player_%d" % player_id
	var energy_label := ui.get_node_or_null(energy_label_path)
	if energy_label and Global.player_ships.has(player_id):
		var ship = Global.player_ships[player_id]
		if ship and ship.has_variable("blue_energy"):
			energy_label.text = "Energy (P%d): %s" % [player_id, str(ship.blue_energy)]

	# HEALTH (optional – gleiche Idee)
	var health_label_path := "health_player_%d" % player_id
	var health_label := ui.get_node_or_null(health_label_path)
	if health_label and Global.player_ships.has(player_id):
		var ship2 = Global.player_ships[player_id]
		if ship2 and ship2.has_variable("health"):
			health_label.text = "Health (P%d): %s" % [player_id, str(ship2.health)]
