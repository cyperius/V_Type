extends GPUParticles2D

@onready var head: Sprite2D = %Head


func _process(_delta: float) -> void:
	var direction_2d := Vector2.LEFT.rotated(head.rotation + 25).normalized()
	var direction := Vector3(direction_2d.x, direction_2d.y, 0.0)
	var material := process_material as ParticleProcessMaterial

	material.direction = direction
	material.initial_velocity_min = 300.0
	material.initial_velocity_max = 300.0  # Keine Geschwindigkeitsspanne
	material.spread = 0.0  # <-- WICHTIG: Keine Streuung der Richtung!
	material.gravity = Vector3.ZERO
