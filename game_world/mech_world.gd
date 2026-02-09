extends Node2D

@export var min_move_speed_factor : float = 1.0
@export var possible_max_move_speed_factor : float = 4.0
var chosen_max_move_speed_factor : float
@export var basic_move_speed : float = 250.0
@export var min_rotation_speed : float = 0.5
@export var max_rotation_speed : float = 3.0


#Referenzen zu MechWorld Nodes
@onready var steel_girders_group_1: Node2D = %SteelGirdersGroup1
@onready var steel_girders_group_2: Node2D = %SteelGirdersGroup2
# Referenz zum Level_Node (RootNode)
@onready var level_7: Node2D = $".."


@onready var girders_1 : Array = []
@onready var girders_2 : Array = []
var girders_stats : Dictionary = {}
var move_direction_y : float = 0 # wird in set_girder_stats() zufällig gesetzt
var move_direction_y_range : float = 0 # wird in set_grider_stats schrittweise erhöht
var rotation_direction : int = 1
var phase1_fadeout := false
var phase2_fadeout := false





func _ready() -> void:
	level_7.end_phase1.connect(_on_end_phase1)
	level_7.end_phase2.connect(_on_end_phase2)
	girders_1 = steel_girders_group_1.get_children()
	for girder in girders_1: # Werte initial einmal setzen, damit physics_process funktionieren kann
	# Jeder girder im Array girders...
		girders_stats[girder] = {} # "wird ein key im Dictionary girder_stats erstellt. Dieser key 
		#enthält jeweils wieder einen Dictionary
		# nun werden die beiden keys diesen inneren Dictionaries definiert und ihnen values zugeordnet
		# hier wird bewusst randi_range mit float Argumenten gewählt -> erst nach 10 Durchläufen kommt eine Erhöhung
		girders_stats[girder]["move_speed"] = basic_move_speed * randi_range(min_move_speed_factor, max_rotation_speed)
		girders_stats[girder]["rotation_speed"] = randf_range(min_rotation_speed, max_rotation_speed)
		girders_stats[girder]["move_direction_y"] = 0
		girders_stats[girder]["rotation_direction"] = rotation_direction
		set_girder_stats_range()
		girder.area_entered.connect(_on_area_entered)
		girder.add_to_group("obstacles")
		
		
	girders_2 = steel_girders_group_2.get_children()
	for girder in girders_2: # Werte initial einmal setzen, damit physics_process funktionieren kann
	# Jeder girder im Array girders...
		girders_stats[girder] = {} # "wird ein key im Dictionary girder_stats erstellt. Dieser key 
		#enthält jeweils wieder einen Dictionary
		# nun werden die beiden keys diesen inneren Dictionaries definiert und ihnen values zugeordnet
		# hier wird bewusst randi_range mit float Argumenten gewählt -> erst nach 10 Durchläufen kommt eine Erhöhung
		girders_stats[girder]["move_speed"] = basic_move_speed * randi_range(min_move_speed_factor, max_rotation_speed)
		girders_stats[girder]["rotation_speed"] = randf_range(min_rotation_speed, max_rotation_speed)
		girders_stats[girder]["move_direction_y"] = 1
		girders_stats[girder]["rotation_direction"] = rotation_direction
		set_girder_stats_range()
		girder.area_entered.connect(_on_area_entered)
		girder.add_to_group("obstacles")
		
	
			
func _physics_process(delta: float) -> void:
	if level_7.phase_1_activated:
		for girder in girders_1: # Bewegung der Girders; Werterange wird jeweils in set_girders_stats_range
			# erweitert und danach werden die Werte zufällig neu gesetzt
			girder.global_position += girders_stats[girder]["move_speed"] * delta * Vector2(-1, girders_stats[girder]["move_direction_y"])
			girder.rotation += girders_stats[girder]["rotation_speed"] * delta * girders_stats[girder]["rotation_direction"]
			if girder.global_position.x <= -200 or girder.global_position.y < -200 or girder.global_position.y > 2600: 
				# wenn ausserhalb des Bildes: neue Zufallsstats setzen und rechts respawnen
				set_girder_stats_range() # respawnen, Werte-range erweitern, danach werden Werte zufällig gesetzt
				girder.global_position = Vector2(4300, randi_range(100, 2400)) # wichtig, x und y Koordinaten in einem setzen,
				# damit es keinen Zwischenzustand gibt (-> hat zu Aufblitzen des Sprites geführt)
				girder.reset_physics_interpolation() # nach Teleport empfohlen, wenn mit physics_process gearbeitet wird
				if phase1_fadeout == false:
					girders_stats[girder]["move_speed"] = randi_range(min_move_speed_factor, chosen_max_move_speed_factor) * basic_move_speed
					girders_stats[girder]["rotation_speed"] = randf_range(min_rotation_speed, max_rotation_speed)
					girders_stats[girder]["move_direction_y"] = randf_range(-1 * move_direction_y_range, move_direction_y_range)
					girders_stats[girder]["rotation_direction"] = [1, -1].pick_random()
				else:
					girders_stats[girder]["move_speed"] = 0
					girders_stats[girder]["rotation_speed"] = 0
			
	if level_7.phase_2_activated == true:
		for girder in girders_2: # Bewegung der Girders; Werterange wird jeweils in set_girders_stats_range
			# erweitert und danach werden die Werte zufällig neu gesetzt
			girder.global_position += girders_stats[girder]["move_speed"] * delta * Vector2(-1, girders_stats[girder]["move_direction_y"])
			girder.rotation += girders_stats[girder]["rotation_speed"] * delta * girders_stats[girder]["rotation_direction"]
			if girder.global_position.x <= -200 or girder.global_position.y > 2600: 
				# wenn ausserhalb des Bildes: respawnen und neue Zufallsstats setzen 
				girder.global_position = Vector2(randi_range(2000, 4000), -400)
				girder.reset_physics_interpolation()
				
				if phase2_fadeout == false:
					set_girder_stats_range() # respawnen, Werte-range erweitern, danach werden Werte zufällig gesetzt
					girders_stats[girder]["move_speed"] = randi_range(min_move_speed_factor, chosen_max_move_speed_factor) * basic_move_speed
					girders_stats[girder]["rotation_speed"] = randf_range(min_rotation_speed, max_rotation_speed)
					girders_stats[girder]["move_direction_y"] = randf_range(0.5, move_direction_y_range)
					girders_stats[girder]["rotation_direction"] = [1, -1].pick_random()
				else:
					girders_stats[girder]["move_speed"] = 0
					girders_stats[girder]["rotation_speed"] = 0
			
		
func set_girder_stats_range() -> void:
	possible_max_move_speed_factor += 0.01
	chosen_max_move_speed_factor = randf_range(min_move_speed_factor, possible_max_move_speed_factor)

	max_rotation_speed += 0.01
	max_rotation_speed = clamp(max_rotation_speed, 0.5, 6.0)

	move_direction_y_range += 0.01
	move_direction_y_range = clamp(move_direction_y_range, 0.0, 0.2)

	
func _on_end_phase1() -> void:
	phase1_fadeout = true
	
func _on_end_phase2() -> void:
	phase2_fadeout = true

func _on_area_entered(other: Area2D) -> void:
	print("mech_world.gd: it actually worked")
	
