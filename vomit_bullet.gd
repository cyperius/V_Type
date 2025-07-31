extends Area2D

var velocity: Vector2 = Vector2.ZERO
const LIFETIME := 8.0  # Sekunde
var timer := 0.0
@export var hit_effect : String = "reverse_controls"

func _ready():
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	position += velocity * delta
	timer += delta
	if timer > LIFETIME:
		queue_free()

func _on_area_entered(area: Node):
	print("vomittet on player")
		
