class_name SpaceBall extends CharacterBody2D

@export var speed : int = 3000
@export var damage : float = 20



func _physics_process(delta: float) -> void:
	
	var direction := Vector2.ZERO
	direction.x = Input.get_axis("ball_left", "ball_right")
	direction.y = Input.get_axis("ball_up", "ball_down")
	var velocity = speed * direction
	position += velocity * delta
	rotate(0.02)
	
	move_and_slide()
