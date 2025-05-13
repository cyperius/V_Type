extends RigidBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var area2d = $Area2D
@onready var explosion_animation = preload("res://scenes/explosion_animation.tscn").instantiate()
@export var health = 200
@export var speed = 500
@export var angle : float = (deg_to_rad(180))
@export var direction = Vector2.RIGHT.rotated(angle)

var scale_factor_rounded

signal asteroid_destroyed(size)


# Bildschirmgrösse
const SCREEN_SIZE = Vector2(3840, 2160)

func _ready() -> void:
	animated_sprite.play("astroid_rotating")
	asteroid_destroyed.connect(Callable(get_parent(), "_on_asteroid_destroyed"))

	
	
	can_sleep = false
	sleeping = false
	
	apply_space_physics(self)

	# Zufällige Skalierung
	var scale = randf_range(1, 2.0)
	scale_factor_rounded = round(scale)
	animated_sprite.scale = Vector2(scale, scale)
	# "health" und Basisschaden, den Asteroid anrichtet, wird mit seiner Grösse multipliziert
	area2d.damage *= scale
	health *= scale

	# Kollision anpassen (z. B. CircleShape2D)
	if collision_shape.shape is CircleShape2D:
		var shape = collision_shape.shape.duplicate() as CircleShape2D
		shape.radius *= scale
		collision_shape.shape = shape

	# Masse basierend auf Volumen-
	mass = scale * scale * scale


	# Zufällige Geschwindigkeit
	speed = randf_range(400, 600)
	# Winkel bestimmen für schräg nach links-unten oder links-oben
	angle = randf_range(deg_to_rad(170), deg_to_rad(190))
	

# Bewegung und Drehung setzenﬁ
	linear_velocity = direction * speed
	angular_velocity = randf_range(-3.0, 3.0)

	# Startposition rechts ausserhalb vom sichtbaren Bereich
	if position == Vector2.ZERO:
		position = Vector2(SCREEN_SIZE.x + randf_range(1000, 4000), randf_range(0, SCREEN_SIZE.y))
	#print("start_position:", global_position)
	
	
	
func _process(delta: float) -> void:
	if global_position.x <= - 20 or global_position.y > 3000 or global_position.y < -1000:
		queue_free()
		

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var pos = state.transform.origin


func apply_space_physics(body: RigidBody2D) -> void:
	# Keine lineare oder rotatorische Dämpfung
	body.linear_damp = 0
	body.angular_damp = 0
	
	# Keine Gravitation
	body.gravity_scale = 0
	
	# Optional: perfektes elastisches Verhalten
	var mat = PhysicsMaterial.new()
	mat.friction = 0
	mat.bounce = 1
	body.physics_material_override = mat


func _on_area_2d_area_entered(area: Area2D) -> void:
	var damage_inflicted = area.damage
	take_damage(damage_inflicted)
	
	
func take_damage(damage) -> void:
	health -= damage
	#print("health: ", health, "damage: ", damage)
	if health <= 0:
		AudioManager.play_sfx_string("explosion", 1)
		get_tree().current_scene.add_child(explosion_animation)
		explosion_animation.scale *= 0.5 * scale
		explosion_animation.speed_scale = 2
		explosion_animation.position = global_position
		emit_signal("asteroid_destroyed", scale_factor_rounded)
		queue_free()
