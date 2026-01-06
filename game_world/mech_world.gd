extends Node2D

@export var min_move_speed_factor : float = 1.0
@export var possible_max_move_speed_factor : float = 4.0
var chosen_max_move_speed_factor : float
@export var basic_move_speed : float = 250.0
@export var min_rotation_speed : float = 0.5
@export var max_rotation_speed : float = 3.0


#Referenzen zu MechWorld Nodes

@onready var steel_girders: Node2D = %SteelGirders

#
#@onready var move_speed : float = 2
#@onready var move_direction : Vector2 = Vector2(-100, 0)

@onready var girders : Array = []
var girders_stats : Dictionary = {}
var move_direction_y : float = 0 # wird in set_girder_stats() zufällig gesetzt
var move_direction_y_range : float = 0 # wird in set_grider_stats schrittweise erhöht
var rotation_direction : int = 1

func _ready() -> void:
	girders = steel_girders.get_children()
	for girder in girders: # Werte initial einmal setzen, damit physics_process funktionieren kann
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
		var girder_area = girder.get_node("Area2D")
		girder_area.area_entered.connect(_on_area_entered)
		girder.is_in_group("obstacles")
		
	
			
func _physics_process(delta: float) -> void:
	for girder in girders: # Bewegung der Girders; Werterange wird jeweils in set_girders_stats_range
		# erweitert und danach werden die Werte zufällig neu gesetzt
		girder.position += girders_stats[girder]["move_speed"] * delta * Vector2(-1, girders_stats[girder]["move_direction_y"])
		girder.rotation += girders_stats[girder]["rotation_speed"] * delta * girders_stats[girder]["rotation_direction"]
		if girder.position.x <= -200 or girder.position.y < -200 or girder.position.y > 2600: 
			# wenn ausserhalb des Bildes: neue Zufallsstats setzen und rechts respawnen
			set_girder_stats_range() # respawnen, Werte-range erweitern, danach werden Werte zufällig gesetzt
			girders_stats[girder]["move_speed"] = randi_range(min_move_speed_factor, chosen_max_move_speed_factor) * basic_move_speed
			girders_stats[girder]["rotation_speed"] = randf_range(min_rotation_speed, max_rotation_speed)
			girders_stats[girder]["move_direction_y"] = randf_range(-1 * move_direction_y_range, move_direction_y_range)
			girders_stats[girder]["rotation_direction"] = [1, -1].pick_random()
			girder.position.x = 4300
			girder.position.y = randi_range(100, 2400)
			print("grider_move_speed ", girders_stats[girder]["move_speed"])
			
			
func set_girder_stats_range() -> void:
	#min_move_speed_factor += 0.01 # range für Geschwindigkeiten erhöhen 
	# (da Endgeschwindigkeit über rangi_rage berechnet wird, erst ab 10 Durchläufen wirksam)
	possible_max_move_speed_factor += 0.01
	chosen_max_move_speed_factor = randf_range(min_move_speed_factor, possible_max_move_speed_factor)
	#min_rotation_speed += 0.01 # range für Rotationsgeschwindîgkeit erhöhen
	max_rotation_speed += 0.01
	max_rotation_speed = clamp(max_rotation_speed, max_rotation_speed, 6)
	# y-Bewegung: mögliche range erhöhen und Richtung zufällig wählen lassen
	move_direction_y_range += 0.01
	move_direction_y_range = clamp(move_direction_y_range, move_direction_y_range, 0.2)
	

func _on_area_entered(other: Area2D) -> void:
	print("it actually worked")
	
