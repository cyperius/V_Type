extends CharacterBody2D

const SPEED    = 80.0
const GRAVITY  = 900.0

var direction  = -1  # 1 = rechts, -1 = links

@onready var wall_ray: RayCast2D = $WallRay
@onready var floor_ray: RayCast2D = $FloorRay
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


func _physics_process(delta: float) -> void:
	# Schwerkraft anwenden
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Horizontale Bewegung
	velocity.x = SPEED * direction
	move_and_slide()

	_check_direction()
	_update_sprite()

func _check_direction() -> void:
	# Raycast-Richtung anpassen (immer nach vorne zeigen)
	wall_ray.target_position.x  = 20 * direction
	#floor_ray.position.x        = 16 * direction

	# Wand voraus ODER kein Boden mehr → umkehren
	var hits_wall    = wall_ray.is_colliding()
	var no_floor     = not floor_ray.is_colliding()

	if hits_wall or no_floor:
		direction *= -1

func _update_sprite() -> void:
	animated_sprite_2d.flip_h = direction < 0 # direction ist -1 oder 1 
	# entsprechen d ist der Ausdruck direction < 0  true oder false -> flip-h wird true oder false
