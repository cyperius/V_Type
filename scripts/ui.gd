extends Control

# Diese onready-Zeilen sind notwendig, damit ich von einer übergeordneten Szene,
# in welcher diese UI-Szene instantiert wird, auf diese Varaiabeln zugreifen kann
# z.B. kann ich dann in der übergeordneten Szene schreiben: ui.score += 1
@onready var asteroids_counter = $AsteroidsCounter
@onready var score = $Score

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
