class_name LevelBase
extends Node2D

signal level_finished(next_level_nr: int, gained_score: int, gained_energy: int)
#signal flight_mode_switch_initiated

# Festlegung der Level Parameter #
@export var amount_of_enemies: int
@export var level_nr : int = 1
@export var last_level := false
@export var auto_thrust_enabled := false
@export var camera_scrolling := false
@export var camera_scroll_speed := 200.0
@export var zoom_factor : Vector2 = Vector2(1, 1)

	
# -- levelspezifische optics und Platzierung für das player_ship -- #
@export_range(0.1, 2.0, 0.05) var ship_scale : float = 1
enum Rotations { R0 = 0, R90 = 90, R180 = 180, R270 = 270 }
@export var player_rotation: Rotations = Rotations.R0
@export var flight_mode: PlayerShip.FlightMode = PlayerShip.FlightMode.LEFT_RIGHT
@export_enum("neutral", "top_down") var skin = "neutral"
var base_position : Vector2 # wird hier definiert, damit unten der Wert für base_position 
# dem "match FLIGHTMode" entsprechend gesetzt werden kann und danach
# "player.global_position = base_position + player_offset" nur 1x geschrieben werden muss

# Referenzen zu Nodes
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var enemy_spawner: Node2D = $EnemySpawner
@onready var enemies_container: Node2D = $EnemiesContainer
@onready var spawned_enemies = 0
@onready var background: Control = $background_Control
@onready var background_texture_rect: TextureRect = $background_Control/background_TextureRect
@onready var camera: Camera2D = get_tree().current_scene.get_node("%Camera2D")


func _ready() -> void:
	add_to_group("levels")
	
	# -- settings for visible world --
	camera.position = Vector2(0, 0)
	background_texture_rect.size /= zoom_factor   # 8.2.2026: allenfalls analoge lösung für level mit anderem skript?
	
	
	# Levelstart: Zerstörte IDs zurücksetzen
	Global.reset_round_state()
	# Alle registrierten Spieler ins Level setzen
	_place_all_players_in_current_level()

	# ── Global Signale
	#das Global.roster_changed Signal feuert, wenn die Anz. Spieler geändert hat
	# wenn dies der Fall, werden gewisse Level Pramter angepasst -> func _on_number...
	Global.roster_changed.connect(_on_number_of_players_changed)

	# ── Enemy‑Spawner Signale
	if enemy_spawner:
		if enemy_spawner.has_signal("boss_defeated"):
			enemy_spawner.connect("boss_defeated", Callable(self, "_on_boss_defeated")) # alte Schreibweise okay
		#enemy_spawner.enemy_spawned.connect(_on_enemy_spawned)
		if enemy_spawner.has_signal("incoming_boss"):
			enemy_spawner.incoming_boss.connect(_on_incoming_boss) #Invalid access to property or key 'incoming_boss' on a base object of type 'Node2D (AsteroidSpawner.gd)'.

	# Optional: Boss‑Timer
	#boss_timer.timeout.connect(_on_boss_timer_timeout)


func _process(delta: float) -> void:
	# Sicherheitsabfrage, ob mind. 1 enemy gespawnt ist (nur damit genug Zeit da ist, um in current_level
	# den aktuellen level zu referenzieren und ob "amount_of_ememies" existiert 
	if enemy_spawner.at_least_one_enemy_spawned:
		if enemy_spawner.enemy_counter >= amount_of_enemies and enemy_spawner.boss_spawned == false:
			enemy_spawner.here_comes_the_boss()
			

func _place_all_players_in_current_level() -> void:
	for player_id in Global.player_ships.keys():
		var player := Global.get_player_ship(player_id)
		if player is PlayerShip:
			place_player_in_current_level(player, player_id)
			# print(" (level_base.gd): nr of players : ", player_id)


func place_player_in_current_level(player: PlayerShip, player_id: int) -> void:
	
	player.hide()
	# 1) Grundzustände (Player Rotation und Flight Mode im Inspector setzen)
	player.mode = flight_mode # Verhalten definiert im player_ship.gd
	player.rotation_degrees = player_rotation
	player.collision_mask = (1 << 2) | (1 << 3) | (1 << 4) | (1 << 5) | (1 << 6)| (1 << 7) 
	# so zu lesen: Bsp. (1 << 2): 
	# 1 wird 2 Bits nach links geschoben; ergibt: 000100 (binär) → Layer 3
	# player reagiert also auf collision_mask (1 << 2) =3; auf (1 << 3) = 4; usw.
	player.collision_layer = 1
	# print(" i'm placed in the level (player ", player, ")")

	# 2) Positionierung im Level 
	# Erfassung Bildschirmgrösse und Defintion Offset pro Spieler
	var viewport_size: Vector2 = get_viewport_rect().size 
	var player_offset = Vector2(180, 60 + 240 * (player_id - 1))
	
	# Positionierung gemäss FlightMiode (im Inspector setzen)
	match flight_mode:
		PlayerShip.FlightMode.DOWN_UP:	
			base_position = Vector2(viewport_size.x * 0.4, viewport_size.y * 0.9)
			# print("flight mode is..", PlayerShip.FlightMode.DOWN_UP)
			
		PlayerShip.FlightMode.LEFT_RIGHT:
			base_position = Vector2(viewport_size.x * 0.1, viewport_size.y * 0.2)
			# print("flight mode is..", PlayerShip.FlightMode.LEFT_RIGHT)
			print("my placed position: ", player.global_position)
			player.auto_thrust_enabled = auto_thrust_enabled
			
			
	player.global_position = base_position + player_offset
			
	
	# 3) Grösse des Spielers (im Inspector setzen)
	player.scale = Vector2(ship_scale, ship_scale)

	# 4) Sichtbar schalten
	player.show()
	
	# 5) je nach Level passende Skin setzen (auch im Inspector)
	player.set_skin(skin)
	
	# 6) player Signale verbinden
	player.connect_signals()


func _on_boss_timer_timeout() -> void:
	pass


func _on_boss_defeated() -> void:
	if last_level: # wenn der Level via Inspector als letzter Level markiert ist: 
		# loop_counter um1 erhöhen und zurück zu wieder Level1
		GameManager.loop_counter += 1
		emit_signal("level_finished", 1, 0, 0)
	else: # ansonsten den nächsten Level laden
		emit_signal("level_finished", level_nr + 1, 0, 0)
	print("boss defeated")


func _on_incoming_boss() -> void:
	audio_stream_player.stop()
		
		
func _on_number_of_players_changed() -> void:
	if enemy_spawner:
		enemy_spawner.set_spawn_rate() # die Funktion wird auch bei der Instanzierung
		#eines neuen Levels aufgerufen
	
func _print_test() ->void:
	print("print_method executed")
