extends Node2D

# ──────────────────────────────────────────────────────────────
#   SIGNALS
# ──────────────────────────────────────────────────────────────
signal player_removed(player_id: int)

# ──────────────────────────────────────────────────────────────
#   REFERENCES
# ──────────────────────────────────────────────────────────────
@onready var level_container: Node = $LevelContainer
var level : Node # Gloable Varaible, Referenz wird in ready-Funktion gesetzt
@onready var players_root: Node2D = $LevelContainer/PlayersRoot
@onready var ui: Control = %UI
@onready var camera: Camera2D = %Camera2D
@onready var scroll_anchor: Node2D = %ScrollAnchor
var scroll_x := 0.0

@onready var ball: SpaceBall = $Ball

@onready var player_scene: PackedScene = preload("res://players/player_ship.tscn")

var input_joiner: Node = null

# ──────────────────────────────────────────────────────────────
#   OPTICS
# ──────────────────────────────────────────────────────────────

@export var default_zoom_x := 1.0
@export var default_zoom_y := 1.0


# ──────────────────────────────────────────────────────────────

# Nur einmal Level laden – niemals mehrfach
var level_loaded_once := false
var tw = create_tween()   # tw wird später einen tween referenzieren (mit create_tween() )
# tw ist als globale Variable definiert, damit der tween von einer anderen Funktion 
# her, gestoppt werden kann -> tw.kill()


# ──────────────────────────────────────────────────────────────
#   READY
# ──────────────────────────────────────────────────────────────
func _ready() -> void:
	
	#print("Main.gd READY – registrierte Spieler:", Global.player_ships)
	
	# Level loaded Signal des GameManagers verbinden
	GameManager.level_loaded.connect(_on_level_loaded)
	
	# InputJoiner suchen
	if has_node("InputJoiner"):
		input_joiner = $InputJoiner
	else:
		push_warning("⚠️ Kein InputJoiner unter Main gefunden.")

	# Player-Join-Events hören (Autoload + InputJoiner)
	Players.player_joined.connect(_on_player_joined)
	if input_joiner:
		input_joiner.player_joined.connect(_on_player_joined)
		input_joiner.player_left.connect(_on_player_left)

	# Bereits aktive Spieler übernehmen (z. B. wenn Gamepad schon verbunden)
	var initial_ids: Array = []
	if input_joiner and input_joiner.has_method("get_active_player_ids"):
		initial_ids = input_joiner.get_active_player_ids()
	else:
		initial_ids = Players.get_active_player_ids()

	for pid in initial_ids:
		_on_player_joined(pid, pid)

	# Weitere Signals
	player_removed.connect(GameManager._on_player_removed)

	# Keine Level-Ladung an dieser Stelle!
	# → erst wenn Spieler existieren, wird geladen.


# ──────────────────────────────────────────────────────────────
# ──────────────────────────────────────────────────────────────
#   PHYSICS DEMO-JOIN (Keyboard als Device 0)
# ──────────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:

	# Debug-Ausgabe optional
	#print("Main physics running…")

	# Taste drücken, um einen Spieler mit Device 0 (Keyboard) zu joinen
	if Input.is_action_just_pressed("join_game"):
		var player_id := Players.join(0)    # 0 = Keyboard-Device
		if player_id != -1:
			# Players.join() sendet das player_joined-Signal
			# und Main._on_player_joined() wird automatisch aufgerufen.
			print("Keyboard join triggered, player_id:", player_id)
			
	# Wenn der Level camera_scrolling aktiviert hat (ExportVariable), Scrolling aktivieren
	# die Referenz auf das Level wird in der "_on_level_loaded()" Funktion gesetzt
	if level != null and "camera_scrolling" in level:
		print("camera_scrolling: ", level.camera_scrolling)
		if level.camera_scrolling == true:
			scroll_x += 200.0 * delta
			var snapped_x: int = int(floor(scroll_x)) 
			scroll_anchor.position.x = snapped_x
			camera.position.x = snapped_x
			camera.global_position.y = int(camera.global_position.y)
			
			
			#
			#
			#scroll_anchor.position.x += (200 * delta)
			##camera.global_position = scroll_anchor.global_position
#
			#var cam_pos := scroll_anchor.position
			#cam_pos.x = round(cam_pos.x)
			#cam_pos.y = round(cam_pos.y)
			#camera.position = cam_pos
				#


# ──────────────────────────────────────────────────────────────
#   SPIELER JOIN
# ──────────────────────────────────────────────
func _on_player_joined(player_id: int, _device_id: int) -> void:
	# print("✅ _on_player_joined aufgerufen, player_id:", player_id, " device_id:", device_id)


	# WICHTIG: Erster Spieler? → Dann Level laden
	if not level_loaded_once:
		level_loaded_once = true
		await _load_game_level()

	# Jetzt Spieler spawnen
	_spawn_player(player_id)

	# UI aktualisieren
	GameManager._register_player_score_and_update_ui(player_id)
	GameManager._update_player_ui(player_id)


# ──────────────────────────────────────────────────────────────
#   LEVEL LADEN
# ──────────────────────────────────────────────────────────────
func _load_game_level() -> void:
	# print("⭐ Lade Level, weil Spieler existieren …")

	# GameManager vorbereiten
	GameManager.set_state(GameManager.STATE_PLAYING)
	GameManager.register_level_container(level_container)

	# Level laden
	GameManager._load_level(GameManager.current_level)

	# Warten, bis Level im Tree erscheint
	await _ensure_level_ready()

	# Level-Signale verbinden
	_connect_level_signals()

	print("🌟 Level erfolgreich geladen.")


# Wartet, bis der Level wirklich im Tree hängt
func _ensure_level_ready() -> void:
	var attempts := 0
	while attempts < 180:
		for child in level_container.get_children():
			# PlayersRoot ignorieren
			if child != players_root:
				return
		await get_tree().process_frame
		attempts += 1


# ──────────────────────────────────────────────────────────────
#   SPIELER SPAWNEN / LEFT
# ──────────────────────────────────────────────────────────────
func _spawn_player(player_id: int) -> void:
	# print("🚀 Spawn Player:", player_id)

	var ship: PlayerShip = player_scene.instantiate()
	ship.player_id = player_id
	ship.mode = ship.FlightMode.LEFT_RIGHT

	players_root.add_child(ship)

	# Sprite/Visual finden
	var visual_node := _get_visual_node_for_player(ship)

	# Spieler global registrieren
	Global.register_player(player_id, ship, visual_node)

	# Positionierung abhängig vom Level
	_place_player_in_current_level(ship, player_id)

	ship.visible = true
	ship.set_process(true)
	ship.set_physics_process(true)


func _on_player_left(player_id: int) -> void:
	_remove_player(player_id)
	GameManager._update_global_ui()
	GameManager._update_all_players_ui()


func _remove_player(player_id: int) -> void:
	if Global.player_ships.has(player_id):
		var ship := Global.player_ships[player_id]
		if is_instance_valid(ship):
			ship.queue_free()

	Global.unregister_player(player_id)
	emit_signal("player_removed", player_id)


# ──────────────────────────────────────────────────────────────
#   PLAYER PLATZIEREN IM LEVEL
# ──────────────────────────────────────────────────────────────
func _place_player_in_current_level(player_ship: PlayerShip, player_id: int) -> void:
	var level := GameManager.current_level_node
	if level and level.has_method("place_player_in_current_level"):
		level.place_player_in_current_level(player_ship, player_id)
	else:
		# Standard-Spawn (links unten in der Safe-Zone)
		var viewport := get_viewport_rect().size
		var base := viewport * 0.05
		var offset := Vector2(180, 60 + 240 * (player_id - 1))
		player_ship.global_position = base + offset


func _get_visual_node_for_player(player_ship: Node) -> Node:
	if player_ship.has_node("Sprite2D"):
		return player_ship.get_node("Sprite2D")
	if player_ship.has_node("AnimatedSprite2D"):
		return player_ship.get_node("AnimatedSprite2D")
	return player_ship


# ──────────────────────────────────────────────────────────────
#   LEVELSIGNALS VERBINDEN
# ──────────────────────────────────────────────────────────────
func _connect_level_signals() -> void:
	var level := GameManager.current_level_node
	if level == null:
		print("⚠️ Kein Level gefunden für Signalverbindung.")
		return
	# print("main: connect_level_signals – Kinder:", level_container.get_child_count())

	if level.has_signal("zoom_requested"):
		level.zoom_requested.connect(_on_zoom_requested)


func _on_level_loaded() -> void:
	tw.kill() # falls noch ein tween von "func _on_zoom_requested" laufen würde
	var level = level_container.get_child(1) # das zweite child (1) ist jeweils der level
	if "zoom_factor" in level:
		var level_zoom_factor : Vector2 = level.zoom_factor
		print("main.gd: Lvel_zoom_factor: ", level_zoom_factor)
		camera.zoom = level_zoom_factor
	else:
		camera.zoom = Vector2(default_zoom_x, default_zoom_y)
		# Grösse des Hintergrunds setzen
	level.background.size.x /= (camera.zoom.x)  # geht nicht. Problem: background ist keine Exportvariable des levels.
	level.background.size.y /= camera.zoom.y # 
	 # alternativ auf FullHD-Fenstergröße Vector2(3860, 2160) setzen
	
	await get_tree().process_frame
	# Beim Levelwechsel alle Spieler korrekt platzieren
	for player_id in Global.player_ships.keys():
		var ship := Global.get_player_ship(player_id)
		_place_player_in_current_level(ship, player_id)

	_connect_level_signals()
	# Referenz auf das aktuelle Level
	level = level_container.get_child(1)


func _on_zoom_requested(zx: float, zy: float, t: int) -> void:
	# print("received zoom signal)")
	tw = create_tween()
	tw.set_parallel()
	tw.tween_property(camera, "zoom:x", zx, t)
	tw.tween_property(camera, "zoom:y", zy, t)


func _input(event):
	if event.is_action_pressed("pause"):
		get_tree().paused = true
