extends Node2D

@onready var flame_particles: GPUParticles2D = %FlameParticles
@onready var burn_area: Area2D = %BurnArea
@onready var collision_shape_2d: CollisionShape2D = %CollisionShape2D
@onready var break_timer: Timer = %BreakTimer
@onready var burn_timer: Timer = %BurnTimer




# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#flame_particles.emitting = false
	break_timer.start()
	break_timer.timeout.connect(_on_break_timer_timeout)
	burn_timer.timeout.connect(_on_burn_timer_timeout)
	


func _on_break_timer_timeout() -> void:
	burn_timer.start()
	break_timer.stop()
	print("burn_timer started")
	flame_particles.emitting = true
	collision_shape_2d.disabled = false
	collision_shape_2d.debug_color = Color(1, 1, 1, 0.5)
	
	
func _on_burn_timer_timeout() -> void:
	print ("break_timer started")
	flame_particles.emitting = false
	burn_timer.stop()
	break_timer.start()
	collision_shape_2d.disabled = true
	collision_shape_2d.debug_color = Color(0.2, 0.5, 1, 0.5)
	
