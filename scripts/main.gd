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
var player_scores: Dictionary = {}	# player_id → score

# ──────────────────────────────────────────────────────────────
#   REFERENCES (Editor: stelle sicher, dass PlayersRoot existiert!)
# ──────────────────────────────────────────────────────────────
@onready var level_container: Node = $LevelContainer
@onready var players_root: Node2D = $LevelContainer/PlayersRoot	# <— fester Node im Editor
@onready var ui: Control = $UI
var input_joiner: Node = null
@onready var player_scene: PackedScene = preload("res://scenes/player_ship.tscn")

# ──────────────────────────────────────────────────────────────
#   LEBENSZYKLUS
# ──────────────────────────────────────────────────────────────
func _ready() -> void:
	# 1) InputJoiner als Node in der Szene erwarten (einfach & zuverlässig)
	if has_node("InputJoiner"):
		input_joiner = $InputJoiner
	else:
		push_warning("⚠️ Kein InputJoiner-Node unter Main gefunden.")
		input_joiner = null

	# 2) Signale vom InputJoiner verbinden
	if input_joiner:
		input_joiner.player_joined.connect(_on_player_joined)
		input_joiner.player_left.connect(_on_player_left)

	# 3) Level laden (Level‑Node wird als Geschwister neben PlayersRoot eingefügt)
	GameManager.set_state(GameManager.STATE_PLAYING)
	GameManager.register_level_container(level_container)
	if GameManager.has_signal("level_loaded"):
		GameManager.level_loaded.connect(_on_level_loaded)
	GameManager._load_level(GameManager.current_level)
	_connect_level_signals()
	await _ensure_level_ready()

	# 4) Bereits aktive Spieler spawnen (Pads evtl. schon vor _ready() verbunden)
	var initial_ids: Array = []
	if input_joiner and input_joiner.has_method("get_active_player_ids"):
		initial_ids = input_joiner.get_active_player_ids()
	else:
		initial_ids = Players.get_active_player_ids()	# Fallback über Autoload
	for player_id in initial_ids:
		_on_player_joined(player_id)

	# 5) UI initialisieren
	_update_global_ui()
	_update_all_players_ui()

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("join_game") and Global.player_ships == {}:
		# obiges if-statement entfernen um Mehrfach-Instanzierungen zu erlauben:)
		_on_player_joined(1)
	
	
# ──────────────────────────────────────────────────────────────
#   LEVEL WARTEN (nur bis der erste Level hängt)
# ──────────────────────────────────────────────────────────────
func _ensure_level_ready() -> void:
	var attempts := 0
	while level_container.get_child_count() == 0 and attempts < 120:
		await get_tree().process_frame
		attempts += 1
	# Kein weiteres Handling nötig: PlayersRoot ist persistent und bleibt bestehen.

# ──────────────────────────────────────────────────────────────
#   SPIELER-HANDLING
# ──────────────────────────────────────────────────────────────
func _on_player_joined(player_id: int) -> void:
	if level_container.get_child_count() == 0:
		await _ensure_level_ready()
	_spawn_player(player_id)
	_register_player_in_main(player_id)
	_update_player_ui(player_id)

func _place_all_players_in_current_level() -> void:
	for player_id in Global.player_ships.keys():
		var ship := Global.get_player_ship(player_id)
		if ship is PlayerShip:
			_place_player_in_current_level(ship, player_id)


# Platziert einen Spieler im aktuell geladenen Level (falls Level Methode anbietet),
# sonst Fallback auf deine bisherige „Mitte + Offset“-Logik.
func _place_player_in_current_level(player_ship: PlayerShip, player_id: int) -> void:
	var level := GameManager.current_level_node
	if level != null and level.has_method("place_player_in_current_level"):
		level.place_player_in_current_level(player_ship, player_id)
	else:
		# Fallback: bisherige Standard-Spawnlogik
		var viewport_size = get_viewport_rect().size
		var base_position = viewport_size * 0.05
		var player_offset = Vector2(180, 60 + 240 * (player_id - 1))
		player_ship.global_position = base_position + player_offset


func _on_player_left(player_id: int) -> void:
	_remove_player(player_id)
	_update_global_ui()
	_update_all_players_ui()


func _spawn_player(player_id: int) -> void:
	# 1) Spielerinstanz
	var player_ship: PlayerShip = player_scene.instantiate()
	player_ship.player_id = player_id
	player_ship.mode = player_ship.PlayerMode.FREE	# Basiszustand; Level kann überschreiben

	# 2) In den Tree einfügen (damit global_position/Center-Bezüge funktionieren)
	players_root.add_child(player_ship)

	# 3) Global registrieren (falls _ready() noch nicht gelaufen ist)
	Global.player_ships[player_id] = player_ship

	# 4) UI koppeln
	if player_ship.has_signal("stats_changed"):
		player_ship.stats_changed.connect(func(changed_player_id: int, current_health: int, current_energy: int) -> void:
			var current_score: int = player_scores.get(changed_player_id, 0)
			ui.set_player_ui(changed_player_id, current_score, current_energy, current_health))

	# 5) Level-spezifisch platzieren (oder Fallback in der Helper-Funktion)
	_place_player_in_current_level(player_ship, player_id)

	# 6) Sichtbarkeit/Prozesse aktivieren (Scale NICHT überschreiben, damit Level-Scale erhalten bleibt)
	player_ship.visible = true
	player_ship.set_process(true)
	player_ship.set_physics_process(true)


func _register_player_in_main(player_id: int) -> void:
	player_scores[player_id] = 0
	_update_player_ui(player_id)

func _remove_player(player_id: int) -> void:
	if Global.player_ships.has(player_id):
		var ship = Global.player_ships[player_id]
		if is_instance_valid(ship):
			ship.queue_free()
		Global.player_ships.erase(player_id)
	if Global.player_sprites.has(player_id):
		Global.player_sprites.erase(player_id)
	if player_scores.has(player_id):
		player_scores.erase(player_id)



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

func _on_level_loaded() -> void:
	# 1) Einen Frame warten, bis der neue Level sicher im Scene-Tree hängt
	#    (stellt sicher, dass level-spezifische Nodes wie Marker2D bereits existieren).
	await get_tree().process_frame

	# 2) Spieler bleiben erhalten, da sie unter PlayersRoot hängen.
	#    Jetzt alle EXISTIERENDEN Spieler level-spezifisch platzieren
	#    (ruft pro Spieler level.place_player_in_current_level(), falls vorhanden,
	#    sonst fallback auf Standard-Spawn in _place_player_in_current_level()).
	_place_all_players_in_current_level()

	# 3) Optional: Hier Kameraziel/Level-spezifische Einstellungen aktualisieren.
	#    (z. B. Kamera-Fokus auf ersten aktiven Spieler setzen)


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
