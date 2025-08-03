extends Control

# Diese onready-Zeilen sind notwendig, damit ich von einer übergeordneten Szene,
# in welcher diese UI-Szene instantiert wird, auf diese Varaiabeln zugreifen kann
# z.B. kann ich dann in der übergeordneten Szene schreiben: ui.score += 1
@onready var destroyed_enemies_counter = $EnemiesDestroyed
@onready var score = $Score
@onready var energy = $energy
@onready var health: Label = $Health
@onready var score_2: Label = $Score2
@onready var energy_2: Label = $energy2
@onready var health_2: Label = $Health2


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
