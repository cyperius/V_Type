extends Node

signal level_loaded
signal enemy_destroyed(score: int, energy: int, player_id: int) # durch enemies aufgerufen
signal player_stats_changed (player_id: int, score: int, energy: int, health: int) # in func _ready weiterverbunden.. aber die
# Funktion _on_stats_changed dazu fehlt noch; evtl. stattdessen direkt zu direkt _update_player_ui verbinden?


# Manche Notification-Konstanten wie `NOTIFICATION_ENTER_TREE`, `NOTIFICATION_READY` oder `EXIT_TREE`
# sind in Godot intern bereits im Node definiert – auch wenn sie im Editor nicht immer direkt sichtbar sind.
# `NOTIFICATION_RESIZED` hingegen ist nur in Control-Nodes verfügbar, daher definieren wir **diese eine Konstante manuell**.
const NOTIFICATION_RESIZED = 40

var screen_size: Vector2

# Spielzustände
const STATE_MENU      = "menu"
const STATE_PLAYING   = "playing"
const STATE_PAUSED    = "paused"
const STATE_GAME_OVER = "game_over"

var state: String = STATE_MENU  # Initialzustand

# Persistente Daten
var score         : int        = 0
var inventory     : Dictionary = {}
var energy_units  : int        = 0
var lives         : int        = 3
var loop_counter  : float      = 1.0
# Aktuelles Level als Zahl
var current_level : int = 1    
var total_destroyed_enemies: int = 0
var player_scores: Dictionary = {}	# player_id → score


# Reihenfolge der Level–Szenen
var level_paths   : Array      = [
	"res://levels/level_1.tscn",
	"res://levels/level_2.tscn",
	"res://levels/level_3.tscn",
	"res://levels/level_4.tscn",
	"res://levels/level_5.tscn",
	"res://levels/level_6.tscn",
	"res://levels/level_7_mech_world.tscn"
	# …weitere Levels hier anhängen
]

# Referenz auf den Container in Main, wird von Main übergeben
var level_container: Node = null

# Referenz auf das aktuell geladene Level
var current_level_node: Node = null

# GameOver-Szene (PackedScene) für spätere Instanziierung
var game_over_scene_packed: PackedScene = preload("res://game_world/game_over.tscn")


func _ready():
	screen_size = get_viewport().get_visible_rect().size
	# print("📐 Initiale Fenstergrösse:", screen_size)
	# print("GameManager bereit, aktueller Zustand:", state)
	_connect_game_over_watchers()	# ← NEU: auf Global-Events hören
	
	
	# 5) UI initialisieren
	_update_global_ui()
	_update_all_players_ui()
	
# wird in main aufgerufen
func _register_player_score_and_update_ui(player_id: int) -> void:
	player_scores[player_id] = 0
	_update_player_ui(player_id)


func _on_player_removed(player_id) -> void:
# 3) Lokale Datenstrukturen aufräumen (Score etc.)
	if player_scores.has(player_id):
		player_scores.erase(player_id)
	

func _process(delta):
	if Input.is_action_just_pressed("level_1"):
		jump_to_level(1)
	if Input.is_action_just_pressed("level_2"):
		jump_to_level(2)
	if Input.is_action_just_pressed("level_3"):
		jump_to_level(3)
	if Input.is_action_just_pressed("level_4"):
		jump_to_level(4)
	if Input.is_action_just_pressed("level_5"):
		jump_to_level(5)
	if Input.is_action_just_pressed("level_6"):
		jump_to_level(6)
	if Input.is_action_just_pressed("level_7"):
		jump_to_level(7)
	if Input.is_action_just_pressed("level_8"):
		jump_to_level(8)
	if Input.is_action_just_pressed("level_9"):
		jump_to_level(9)
	if Input.is_action_just_pressed("level_10"):
		jump_to_level(10)
		

func _connect_game_over_watchers() -> void:
	# Alle relevanten Global-Events verbinden (mehrfaches Verbinden vermeiden)
	if not Global.player_registered.is_connected(_on_roster_changed_check_game_over):
		Global.player_registered.connect(_on_roster_changed_check_game_over)
	if not Global.player_unregistered.is_connected(_on_roster_changed_check_game_over):
		Global.player_unregistered.connect(_on_roster_changed_check_game_over)
	if not Global.player_destroyed.is_connected(_on_roster_changed_check_game_over):
		Global.player_destroyed.connect(_on_roster_changed_check_game_over)
	if not Global.player_revived.is_connected(_on_roster_changed_check_game_over):
		Global.player_revived.connect(_on_roster_changed_check_game_over)
	if not Global.roster_changed.is_connected(_on_roster_changed_check_game_over):
		Global.roster_changed.connect(_on_roster_changed_check_game_over)

	# Einmal initial prüfen (z.B. wenn Szene neu geladen wird)
	_on_roster_changed_check_game_over()

func _on_roster_changed_check_game_over(_player_id := -1) -> void:
	# Wenn wir bereits im GameOver sind, nichts mehr tun
	if state == STATE_GAME_OVER:
		return
	# „Alle tot?“ → robust via Global.should_game_over()
	if Global.should_game_over():
		set_state(STATE_GAME_OVER)


func jump_to_level(level_nr: int) -> void:
	await AudioManager.fade_out(4)
	GameManager.current_level = level_nr
	GameManager._load_level(level_nr)

# Notification für Fenstergrößen-Änderung
func _notification(what):
	if what == NOTIFICATION_RESIZED:
		screen_size = get_viewport().get_visible_rect().size
		# print("📐 Fenstergrösse geändert:", screen_size)

# Helfer: Zustand prüfen
func is_playing() -> bool:
	return state == STATE_PLAYING

func is_paused() -> bool:
	return state == STATE_PAUSED

# Container übergeben
func register_level_container(container: Node) -> void:
	level_container = container

# Alle Gegner und Schüsse entfernen
func clear_level():
	get_tree().call_group("enemies", "queue_free")
	get_tree().call_group("projectiles", "queue_free")
	# get_tree().call_group("powerups", "queue_free")

# -------------------------
# State-Management + GameOver-Pause
# -------------------------

# Setzt alle persistenten Werte zurück. Wenn mit true (default) aufgerufen:
# Restart in Level 1, mit "false" aufrufen, um im aktuellen Level zu respawnen
func reset_game_state(full_reset: bool = true) -> void:
	score = 0
	energy_units = 0
	lives = 3
	inventory.clear()

	if full_reset:
		current_level = 1
	

# -------------------------
# State-Management + GameOver-Pause
# -------------------------

func set_state(new_state: String) -> void:
	state = new_state
	match state:
		STATE_PLAYING:
			get_tree().paused = false
		STATE_PAUSED:
			get_tree().paused = true
		STATE_GAME_OVER:
			get_tree().paused = true
			_start_game_over()


func _start_game_over() -> void:
	clear_level()

	var game_over_scene = game_over_scene_packed.instantiate()
	game_over_scene.name = "GameOverScene"

	# GameOver-UI darf laufen, obwohl der Tree pausiert ist
	game_over_scene.process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	level_container.add_child(game_over_scene)

	if game_over_scene.has_signal("finished"):
		game_over_scene.finished.connect(_on_game_over_finished)


func _on_game_over_finished() -> void:
	print("▶ Game Over finished – Reset & Reload Current Scene")

	# 1) GameOver-Szene entfernen
	if level_container and level_container.has_node("GameOverScene"):
		level_container.get_node("GameOverScene").queue_free()

	# 2) Globalen Zustand aufräumen
	Global.clear_all_player_data()
	Global.reset_round_state()

	# 3) Player-Mapping zurücksetzen (sehr wichtig!)
	if Players:
		Players.reset_all()

	# 4) GameManager zurücksetzen
	# Hier nur "Soft-Reset" mit "false": Werte zurücksetzen, aber current_level behalten
	reset_game_state(false)
	state = STATE_MENU

	# 5) Tree wieder freigeben
	get_tree().paused = false

	# 6) Szene RELOADEN (statt change_scene_to_file)
	await get_tree().process_frame
	_restart_to_main()
	var err := get_tree().reload_current_scene()
	print("reload_current_scene result:", err)

	

func _restart_to_main() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _load_level(level_nr: int) -> void:
	#instanziierte Objekte nach Typ entfernen (siehe clean_level() Funktion)
	clear_level()
	
	# Alten Level entfernen
	if current_level_node:
		current_level_node.queue_free()

	# Pfad aus Autoload holen (Array, 0-basiert)
	var path: String = GameManager.level_paths[level_nr - 1]
	
	print("GameManager: loadel level: ", level_nr)
	

	# Szene dynamisch laden und als PackedScene casten
	var packed_scene := ResourceLoader.load(path) as PackedScene
	if not packed_scene:
		push_error("Konnte Level nicht laden: %s" % path)
		return

	# Instanziieren
	current_level_node = packed_scene.instantiate()
	
	# NEU: Sofort prüfen, ob GameOver fällig ist
	_on_roster_changed_check_game_over()
	
	# Persistente Daten übergeben, wenn das Level eine setup-Methode anbietet
	if current_level_node.has_method("setup"):
		current_level_node.setup(GameManager.score, GameManager.energy_units, GameManager.lives, GameManager.inventory)

	# In den Container einfügen
	level_container.add_child(current_level_node)

	# Signal fürs Level-Ende verbinden (Godot 4-Style)
	
	if current_level_node.has_signal("level_finished"):
		current_level_node.connect("level_finished", Callable(self, "_on_level_finished"))
	
	emit_signal("level_loaded")
	
		

func _on_level_finished(next_level_nr: int, gained_score: int = 0, gained_energy: int = 0) -> void:
	# Persistente Daten aktualisieren
	GameManager.score        += gained_score
	GameManager.energy_units += gained_energy
	GameManager.current_level = next_level_nr
	AudioManager.fade_out(4)

	# Nächstes Level laden
	_load_level(current_level)

# Für allfällige spätere Implementierung eines Shops / einer Werkstatt
# func next_state():
#	# Zwischen Level und Shop wechseln
#	if should_show_shop():
#		return "shop"
#	else:
#		return "level"

# func should_show_shop() -> bool:
#	# hier deine Logik, z.B. alle 3 Level
#	pass

# ──────────────────────────────────────────────────────────────
#   SIGNAL-CALLBACKS
# ──────────────────────────────────────────────────────────────
func _on_enemy_hit(score: int, energy: int, player_id: int) -> void:
	print("main: enemy Destroyed")
	total_destroyed_enemies += 1
	if not player_scores.has(player_id):
		player_scores[player_id] = 0
	player_scores[player_id] += score
	if Global.player_ships.has(player_id):
		print("line286: check")
		var ship = Global.player_ships[player_id]
		if ship is PlayerShip:
			print("line289: check")
			ship.blue_energy += energy
			ship.score += score
	_update_global_ui()
	_update_player_ui(player_id)

# ──────────────────────────────────────────────────────────────
#   UI-HILFSFUNKTIONEN
# ──────────────────────────────────────────────────────────────
func _update_global_ui() -> void:
	pass	

func _update_all_players_ui() -> void:
	for player_id in Global.player_ships.keys():
		_update_player_ui(player_id)


func _update_player_ui(player_id: int) -> void:
	var score_count: int = player_scores.get(player_id, 0) # 
	var energy_count: int = 0  # wird gleich unten mit dem richtugen Wert überschrieben ('= 0 notwendig?"
	var health_count: int = 0
	var ship = Global.player_ships.get(player_id, null)
	if ship is PlayerShip:   # ship wird bisschen weiter oben in func _on_enemy_destroyed definiert
		energy_count = ship.blue_energy
		health_count = ship.health
		score_count = ship.score
	emit_signal("player_stats_changed", player_id, score_count, energy_count, health_count)
