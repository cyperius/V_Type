extends "res://scripts/projectiles_basis_class.gd"

@export var blast_scale := Vector2(1, 1)
@export var blast_speed := 400.0

func _ready():
	super._ready()
	speed = blast_speed
	# Spezifische Initialisierung
	$Sprite2D.texture = load("res://assets/graphic_elements/shots/laser_beam1.png")
	
	
