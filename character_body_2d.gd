class_name RollingEnemy 
extends CharacterBody2D


const GRAVITY  = 900.0

var direction  = -1  # 1 = rechts, -1 = links
var just_turned := false

@export var speed = 450
@export var ajusted_scale_x = 0.4
@export var ajusted_scale_y = 0.4
@onready var wall_ray: RayCast2D = %WallRay
@onready var floor_ray: RayCast2D = %FloorRay
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var visible_on_screen_enabler_2d: VisibleOnScreenEnabler2D = %VisibleOnScreenEnabler2D


func _ready() -> void:
	visible_on_screen_enabler_2d.screen_entered.connect(_on_screen_entered)
	visible_on_screen_enabler_2d.screen_exited.connect(_on_screen_exited)
	scale = Vector2(-ajusted_scale_x, ajusted_scale_y)
	var level : Node = get_tree().current_scene.get_node("LevelContainer").get_child(1) # fehleranfälliger Weg zum Level Node
	print("rolling_enemy: var level is...", level)
	var level_scroll_speed : float = level.camera_scroll_speed # Scroll-Geschwindigkeit des Levels holen
	speed -= level_scroll_speed # Speed des Levelscrollings vom Speed des Gegners abziehen 
	#resultierende realtive Endgeschwindigkeit in beide Richtungen gleich schnell, da direrction berücksichtigt bei velocity.x


func _physics_process(delta: float) -> void:
	# Schwerkraft anwenden
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Horizontale Bewegung
	velocity.x = speed * direction
	move_and_slide()

	_check_direction()
	

func _check_direction() -> void:
	# Raycast-Richtung anpassen (immer nach vorne zeigen)
	#wall_ray.target_position.x  = 120 * direction
	#floor_ray.position.x        = 80 * direction

	# Wand voraus ODER kein Boden mehr → umkehren
	var hits_wall    = wall_ray.is_colliding()
	var no_floor     = not floor_ray.is_colliding()
	
	if hits_wall:
		print("wall detected, just_turned = ", just_turned)
		
	if no_floor:
		print("no_floor_detected")
	
	if is_on_floor() and not just_turned: # nur wenn auf Boden stehend und nicht gerade gedreht ausführen
		if hits_wall or no_floor:
			just_turned = true
			direction *= -1
			_update_sprite()
			await get_tree().create_timer(0.2).timeout
			just_turned = false
			

func _update_sprite() -> void:
	scale.x = ajusted_scale_x * -1
	

func _on_screen_entered() -> void:
	set_physics_process(true)
	direction = -1
	
func _on_screen_exited() -> void:
	set_physics_process(false)
	#if not is_dead:
		#queue_free() # Falls queue_free gewünscht muss der is_dead flag noch implemntiert werden (Gegner vor dem damge bedinten zerstören auf is_dead setzen, denn beim zerstört werden feuert Screen_exited auch)
