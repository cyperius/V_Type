class_name LaserBlast
extends "res://scripts/projectiles_basis_class.gd"

@export var blast_scale: Vector2 = Vector2(1, 1)
@export var blast_speed: float = 500.0	# Default & float!

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	# WICHTIG: speed VOR super._ready() setzen (Basis nutzt speed in _ready()).
	speed = blast_speed

	# Scale NICHT am Root ändern (verursacht Warnung) → auf Sprite legen:
	if is_instance_valid(sprite):
		sprite.scale = blast_scale

	super._ready()

	# Optional: Textur setzen, falls gebraucht
	# sprite.texture = load("res://assets/graphic_elements/shots/laser_blast1.png")
