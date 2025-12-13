class_name SpaceBall extends CharacterBody2D

@export var speed : int = 3000
@export var damage : float = 20
@export var ball_activated := false



func _ready() -> void:
	hide()

func _physics_process(delta: float) -> void:
	
	var direction := Vector2.ZERO
	direction.x = Input.get_axis("ball_left", "ball_right")
	direction.y = Input.get_axis("ball_up", "ball_down")
	var velocity = speed * direction
	position += velocity * delta
	rotate(0.02)
	
	if ball_activated:
		show()
	elif ball_activated == false:
		hide()
	
	if Input.is_action_just_pressed("activate_ball"):
		ball_activated =! ball_activated
		

	move_and_slide()
	
	
	
