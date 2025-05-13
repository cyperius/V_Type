extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# Eigene Massendefinition (CharacterBody2D hat keine eingebaute Masse)
var mass: float = 1.0
# Speichert die initiale kinetische Energie (nur translationale Energie)
var initial_energy: float = 0.0
# Bildschirmgröße (anpassen oder dynamisch ermitteln)
var screen_size: Vector2 = Vector2(3840, 2160)
# Eigene Rotationsgeschwindigkeit (CharacterBody2D besitzt keinen eigenen)
var angular_velocity: float = 0.0

func _ready() -> void:
	# Starte die Animation
	animated_sprite.play("astroid_rotating")
	
	# Zufällige Skalierung für Sprite und Kollisionsform
	var random_scale = randf_range(0.5, 2.0)
	animated_sprite.scale = Vector2(random_scale, random_scale)
	
	# Passe die Kollisionsform an, falls es ein CircleShape2D ist
	if collision_shape.shape is CircleShape2D:
		var circle_shape = collision_shape.shape.duplicate() as CircleShape2D
		circle_shape.radius *= random_scale
		collision_shape.shape = circle_shape
	
	# Berechne die Masse proportional zum (ungefähren) Volumen
	mass = random_scale * random_scale * random_scale
	
	# Setze eine zufällige Geschwindigkeit und Richtung
	var speed = randf_range(50, 500)
	var direction = Vector2.RIGHT.rotated(randf_range(0, TAU))
	velocity = direction * speed  # Nutzt die eingebaute velocity von CharacterBody2D
	angular_velocity = randf_range(-3, 3)
	
	# Setze eine zufällige Startposition innerhalb des Bildschirms
	position = Vector2(randf_range(0, screen_size.x), randf_range(0, screen_size.y))
	
	# Speichere die initiale kinetische Energie (E = 0.5 * m * v²)
	initial_energy = 0.5 * mass * speed * speed

func _physics_process(delta: float) -> void:
	# Bewege den Asteroiden; move_and_slide() verwendet die eingebaute velocity
	move_and_slide()
	
	# Prüfe, ob eine Kollision während des Slides aufgetreten ist
	if get_slide_collision_count() > 0:
		# Hole die erste Kollision und rufe die Kollisionsnormalen über get_normal() ab
		var collision = get_slide_collision(0)
		var n: Vector2 = collision.get_normal()
		# Elastischer Stoß: Reflektiere die Geschwindigkeit entlang der Kollisionsnormalen
		velocity = velocity.bounce(n)
		# Normiere den Geschwindigkeitsbetrag, um die kinetische Energie konstant zu halten:
		var desired_speed = sqrt((2 * initial_energy) / mass)
		velocity = velocity.normalized() * desired_speed
	
	# Aktualisiere die Rotation basierend auf angular_velocity
	rotation += angular_velocity * delta
	
	# Toroidales Wrapping: Wenn der Asteroid den Bildschirm verlässt, erscheint er auf der gegenüberliegenden Seite.
	if position.x > screen_size.x:
		position.x -= screen_size.x
	elif position.x < 0:
		position.x += screen_size.x
	
	if position.y > screen_size.y:
		position.y -= screen_size.y
	elif position.y < 0:
		position.y += screen_size.y
