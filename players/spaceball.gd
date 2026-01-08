class_name SpaceBall extends CharacterBody2D

@export var speed : float = 3000 # Velocity ist sowieso float
@export var rotation_speed: float = 1.0
@export var damage : float = 20
@export var ball_activated := false
@onready var area_collision_shape_2d_2: CollisionShape2D = %AreaCollisionShape2D2
@onready var body_collision_shape_2d: CollisionShape2D = %BodyCollisionShape2D



func _ready() -> void:
	_set_active(false)

func _physics_process(delta: float) -> void:
	
	var direction := Vector2(
		Input.get_axis("ball_left", "ball_right"),
		Input.get_axis("ball_up", "ball_down")
	)

	if direction != Vector2.ZERO:
		direction = direction.normalized()

	velocity = direction * speed
	move_and_slide()
	rotate(rotation_speed * delta)
		

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("activate_ball"):
		_set_active(!ball_activated)


func _set_active(is_active: bool) -> void:
	ball_activated = is_active
	visible = is_active
	area_collision_shape_2d_2.disabled = !is_active
	body_collision_shape_2d.disabled = !is_active
	set_physics_process(is_active)
