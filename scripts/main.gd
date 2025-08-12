extends Node2D

# ──────────────────────────────────────────────────────────────
#   SIGNALS
# ──────────────────────────────────────────────────────────────
signal enemy_destroyed(score: int, energy: int, player_id: int)
signal absorbed_energy(amount: int, player_id: int)

# ──────────────────────────────────────────────────────────────
#   GAME STATE
# ──────────────────────────────────────────────────────────────
var total_destroyed_enemies: int = 0
var player_scores: Dictionary = {}  # player_id → score

# ──────────────────────────────────────────────────────────────
#   REFERENCES
# ──────────────────────────────────────────────────────────────
@onready var level_container: Node   = $LevelContainer
@onready var ui: Control             = $UI
var input_joiner: Node = null  # Wird dynamisch gefunden (Node oder Autoload)

# ──────────────────────────────────────────────────────────────
#   LEBENSZYKLUS
# ──────────────────────────────────────────────────────────────
func _ready() -> void:
	# 1️⃣ InputJoiner-Referenz ermitteln
	# Variante A: als Node im Szenenbaum
	if has_node("InputJoiner"):
		input_joiner = $InputJoiner
		print("🔗 InputJoiner als Szenen-Node gefunden.")
	# Variante B: als Autoload
	elif Engine.has_singleton("InputJoiner"):
		input_joiner = InputJoiner
		print("🔗 InputJoiner als Autoload-Singleton gefunden.")
	else:
		push_warning("⚠️ Kein InputJoiner gefunden! Weder im Szenenbaum noch als Autoload.")
		return  # Verhindert spätere Null-Fehler

	# 2️⃣ Signale verbinden
	input_joiner.player_joined.connect(_on_player_joined)
	input_joiner.player_left.connect(_on_player_left)

	# 3️⃣ Bereits existierende Spieler registrieren (z. B. bei Levelwechsel)
	for player_id in Global.player_ships.keys():
		_register_player_in_main(player_id)

	# 4️⃣ Level laden
	GameManager.set_state(GameManager.STATE_PLAYING)
	GameManager.register_level_container(level_container)
	GameManager._load_level(GameManager.current_level)
	_connect_level_signals()

	# 5️⃣ UI initialisieren
	_update_global_ui()
	_update_all_players_ui()

	print("🎯 Active players at start:", Global.player_ships.keys())


# ──────────────────────────────────────────────────────────────
#   SPIELER-HANDLING
# ──────────────────────────────────────────────────────────────
func _on_player_joined(player_id: int) -> void:
	print("➕ Neuer Spieler:", player_id)
	_spawn_player(player_id)
	_register_player_in_main(player_id)
	_update_player_ui(player_id)

func _on_player_left(player_id: int) -> void:
	print("➖ Spieler entfernt:", player_id)
	_remove_player(player_id)
	_update_global_ui()
	_update_all_players_ui()

func _spawn_player(player_id: int) -> void:
	var player_scene := preload("res://scenes/player_ship.tscn")
	var ship := player_scene.instantiate()

	# Spawn-Position abhängig von ID
	ship.global_position = Vector2(500, 1000 + (player_id - 1) * 200)
	ship.scale = Vector2(0.25, 0.25)
	ship.player_id = player_id

	# Registrierung NICHT nötig, PlayerShip._ready() macht das

	# Schiff ins aktuelle Level hängen
	if level_container.get_child_count() > 0:
		var current_level := level_container.get_child(0)
		current_level.add_child(ship)
	else:
		add_child(ship)  # Fallback

func _remove_player(player_id: int) -> void:
	if Global.player_ships.has(player_id):
		var ship = Global.player_ships[player_id]
		if is_instance_valid(ship):
			ship.queue_free()
		Global.player_ships.erase(player_id)
		Global.player_sprites.erase(player_id)
	player_scores.erase(player_id)

func _register_player_in_main(player_id: int) -> void:
	player_scores[player_id] = 0
	_update_player_ui(player_id)


# ──────────────────────────────────────────────────────────────
#   LEVEL-HANDLING
# ──────────────────────────────────────────────────────────────
func _connect_level_signals() -> void:
	if level_container.get_child_count() == 0:
		return
	var current_level: Node = level_container.get_child(0)

	if current_level.has_signal("enemy_destroyed"):
		current_level.enemy_destroyed.connect(_on_enemy_destroyed)

	if current_level.has_signal("level_finished"):
		current_level.level_finished.connect(_on_level_finished)


# ──────────────────────────────────────────────────────────────
#   SIGNAL-CALLBACKS
# ──────────────────────────────────────────────────────────────
func _on_enemy_destroyed(score: int, energy: int, player_id: int) -> void:
	total_destroyed_enemies += 1

	if not player_scores.has(player_id):
		player_scores[player_id] = 0
	player_scores[player_id] += score

	if Global.player_ships.has(player_id):
		var ship = Global.player_ships[player_id]
		if ship is PlayerShip:
			ship.blue_energy += energy

	_update_global_ui()
	_update_player_ui(player_id)

func _on_level_finished(next_level_number: int, gained_score: int = 0, gained_energy: int = 0) -> void:
	pass


# ──────────────────────────────────────────────────────────────
#   UI-HILFSFUNKTIONEN
# ──────────────────────────────────────────────────────────────
func _update_global_ui() -> void:
	if ui and ui.destroyed_enemies_counter:
		ui.destroyed_enemies_counter.text = "Enemies destroyed: %d" % total_destroyed_enemies

func _update_all_players_ui() -> void:
	for player_id in Global.player_ships.keys():
		_update_player_ui(player_id)

func _update_player_ui(player_id: int) -> void:
	if not ui:
		return
	var score_count: int = player_scores.get(player_id, 0)
	var energy_count: int = 0
	var health_count: int = 0

	var ship = Global.player_ships.get(player_id, null)
	if ship is PlayerShip:
		energy_count = ship.blue_energy
		health_count = ship.health

	ui.set_player_ui(player_id, score_count, energy_count, health_count)
