extends Area2D

@onready var rigid_asteroid = $".."
@onready var damage : int = rigid_asteroid.damage
@export var health = 300

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
