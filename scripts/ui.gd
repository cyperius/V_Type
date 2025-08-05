extends Control

# Diese onready-Zeilen sind notwendig, damit ich von einer übergeordneten Szene,
# in welcher diese UI-Szene instantiert wird, auf diese Varaiabeln zugreifen kann
# z.B. kann ich dann in der übergeordneten Szene schreiben: ui.score += 1
@onready var energy_labels := {}
@onready var destroyed_enemies_counter = $EnemiesDestroyed
@onready var score = $Score
@onready var health: Label = $Health
@onready var score_2: Label = $Score2
@onready var health_2: Label = $Health2
@onready var energy: Label = $energy



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var player_nr = 0
	#var font = DynamicFont.new()
	#font.size = 32                                   # Schriftgröße in Punkten
	for player in Global.player_ships:
		player_nr +=1
		var label = Label.new()
		label.text = "Score"
		label.name = "score_player" + str(player_nr)
		#label.font.size = 48
		add_child(label)
		label.global_position = Vector2(0, randi_range(0,500))
		
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
