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
@onready var ui: Control = %UI
var input_joiner: Node = null
@onready var player_scene: PackedScene = preload("res://scenes/player_ship.tscn")
@onready var camera: Camera2D = %Camera2D

# ──────────────────────────────────────────────────────────────
#   LEBENSZYKLUS
# ──────────────────────────────────────────────────────────────
func _ready() -> void:
	GameManager.level_loaded.connect(_on_level_loaded)
	print("registreirte Spieler beim level laden: ", Global.player_ships)
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
	var attempts: int = 0
	while attempts < 180:
		# Warten, bis EIN Kind unter LevelContainer existiert, das NICHT PlayersRoot ist
		var level_is_present: bool = false
		for child in level_container.get_children():
			# Sicherstellen, dass wir PlayersRoot überspringen
			if child != players_root:
				level_is_present = true
				break

		# Optional noch robuster: Wenn GameManager die Instanz referenziert, reicht das
		if level_is_present or GameManager.current_level_node != null:
			return

		await get_tree().process_frame
		attempts += 1
	# Falls wir hier landen, gibt es (noch) keinen Level; kein zusätzliches Handling nötig


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
	# 1) Spielerinstanz erzeugen
	var player_ship: PlayerShip = player_scene.instantiate()
	player_ship.player_id = player_id
	player_ship.mode = player_ship.PlayerMode.FREE	# Basiszustand; Level darf überschreiben

	# 2) In den Tree einfügen (damit Positionen/Kamera/Signale funktionieren)
	players_root.add_child(player_ship)

	# 3) Global korrekt registrieren (ID-basiert, inkl. Sprite/Visual-Referenz wenn vorhanden)
	var visual_node: Node = _get_visual_node_for_player(player_ship)
	Global.register_player(player_id, player_ship, visual_node)

	# 4) UI-Callback verbinden (falls vorhanden)
	if player_ship.has_signal("stats_changed"):
		player_ship.stats_changed.connect(func(changed_player_id: int, current_health: int, current_energy: int) -> void:
			var current_score: int = player_scores.get(changed_player_id, 0)
			ui.set_player_ui(changed_player_id, current_score, current_energy, current_health))

	# 5) Level-spezifisch platzieren (oder Fallback)
	_place_player_in_current_level(player_ship, player_id)

	# 6) Aktivieren (Sichtbarkeit/Processing)
	player_ship.visible = true
	player_ship.set_process(true)
	player_ship.set_physics_process(true)

	# 7) Lokale UI initialisieren
	_update_player_ui(player_id)

func _register_player_in_main(player_id: int) -> void:
	player_scores[player_id] = 0
	_update_player_ui(player_id)

func _remove_player(player_id: int) -> void:
	# 1) Lokale Scene-Instanz ggf. aufräumen (nur falls noch existiert)
	if Global.player_ships.has(player_id):
		var ship: Node = Global.player_ships[player_id]
		if is_instance_valid(ship):
			ship.queue_free()

	# 2) Über Global deregistrieren (entfernt auch Sprite + destroyed-Flag + emittiert Signale)
	Global.unregister_player(player_id)

	# 3) Lokale Datenstrukturen aufräumen (Score etc.)
	if player_scores.has(player_id):
		player_scores.erase(player_id)
		
func _get_visual_node_for_player(player_ship: Node) -> Node:
	# Versuche, einen typischen Visual/Sprite-Knoten zu finden.
	# Passe die Pfade an deine PlayerShip-Szene an, falls du andere Namen verwendest.
	if player_ship.has_node("Sprite2D"):
		return player_ship.get_node("Sprite2D")
	if player_ship.has_node("AnimatedSprite2D"):
		return player_ship.get_node("AnimatedSprite2D")
	# Fallback: nimm das Ship selbst, falls kein dedizierter Sprite-Knoten existiert.
	return player_ship





# ──────────────────────────────────────────────────────────────
#   LEVEL-HANDLING
# ──────────────────────────────────────────────────────────────

func _connect_level_signals() -> void:
	print("main: connect_level_signals – Kinder im LevelContainer:", level_container.get_child_count())

	var current_level: Node = null

	# 1) Bevorzugt über GameManager (verlässlichste Quelle)
	if GameManager.current_level_node != null:
		current_level = GameManager.current_level_node
	else:
		# 2) Fallback: erstes Kind unter LevelContainer, das nicht PlayersRoot ist
		for child in level_container.get_children():
			if child != players_root:
				current_level = child
				break

	if current_level == null:
		print("⚠️ Kein Level-Node gefunden (noch nicht geladen?)")
		return

	# 3) Signale verbinden, wenn vorhanden
	if current_level.has_signal("enemy_destroyed"):
		print("main: (signal enemy_destroyed im Level gefunden)")
		current_level.enemy_destroyed.connect(_on_enemy_destroyed)

	if current_level.has_signal("level_finished"):
		current_level.level_finished.connect(_on_level_finished)

	if current_level.has_signal("zoom_requested"):
		print("main: (signal zoom_requested im Level gefunden)")
		current_level.zoom_requested.connect(_on_zoom_requested)

func _on_level_loaded() -> void:
	# 0) Beim Levelwechsel zunächst zerstörte IDs leeren, damit Platzierung nicht als "tot" gilt
	Global.reset_round_state()

	# 1) Einen Frame warten, bis der neue Level sicher im Scene-Tree hängt
	await get_tree().process_frame
	
	# 2) Spieler bleiben erhalten, da sie unter PlayersRoot hängen.
	#    Jetzt alle EXISTIERENDEN Spieler level-spezifisch platzieren
	#    (ruft pro Spieler level.place_player_in_current_level(), falls vorhanden,
	#    sonst fallback auf Standard-Spawn in _place_player_in_current_level()).
	_place_all_players_in_current_level()
	
#	  3) Signale des Levels verbinden
	_connect_level_signals()

	# 3) Optional: Hier Kameraziel/Level-spezifische Einstellungen aktualisieren.
	#    (z. B. Kamera-Fokus auf ersten aktiven Spieler setzen)


# ──────────────────────────────────────────────────────────────
#   SIGNAL-CALLBACKS
# ──────────────────────────────────────────────────────────────
func _on_enemy_destroyed(score: int, energy: int, player_id: int) -> void:
	print("main: enemy Destroyed")
	total_destroyed_enemies += 1
	if not player_scores.has(player_id):
		player_scores[player_id] = 0
	player_scores[player_id] += score
	if Global.player_ships.has(player_id):
		var ship = Global.player_ships[player_id]
		if ship is PlayerShip:
			ship.blue_energy += energy
			ship.score += score
	_update_global_ui()
	_update_player_ui(player_id)

func _on_level_finished(next_level_number: int, gained_score: int = 0, gained_energy: int = 0) -> void:
	pass

func _on_zoom_requested(zoomfactor_x: float, zoomfactor_y: float) -> void:
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(camera, "zoom:x", zoomfactor_x, 10)
	tween.tween_property(camera, "zoom:y", zoomfactor_y, 10)


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
		score_count = ship.score
	ui.set_player_ui(player_id, score_count, energy_count, health_count)

func _input(event):
	if event.is_action_pressed("pause"):
		get_tree().paused = true
		print("paused gesetzt!")
