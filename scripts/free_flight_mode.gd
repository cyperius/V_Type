class_name FreeFlightModul extends Node

# ──────────────────────────────────────────────────────────────
# PROPERTIES
# ──────────────────────────────────────────────────────────────
var player_id: int
# Referenz auf den CharacterBody2D (wird von PlayerShip gesetzt)
var body: CharacterBody2D
var rotation_speed : float = 2.0 # allenfalls direkt hier oder im Player_Root Node
# als Export-Variable einrichten

func setup(owner_body: CharacterBody2D) -> void:
	body = owner_body
	# Direkt vom Body lesen - keine Doppelzuweisung nötig
	player_id = body.player_id
	
#rotation = direction.angle() - PI
func _physics_free_flying(delta: float) -> void:
	var direction := Vector2.ZERO
	if owner.controls_are_reversed:
		direction.x = Input.get_axis("p%d_right" % player_id, "p%d_left" % player_id)
		direction.y = Input.get_axis("p%d_down" % player_id, "p%d_up" % player_id)
	else:
		direction.x = Input.get_axis("p%d_left" % player_id, "p%d_right" % player_id)
		direction.y = Input.get_axis("p%d_up" % player_id, "p%d_down" % player_id)
	body.rotation += direction.x * delta * rotation_speed
	var speed = body.speed * direction.y
	body.velocity = (-1 * direction.y) * body.speed * Vector2.RIGHT.rotated(deg_to_rad(body.rotation_degrees)) # gelegentlich diese zeile genau studieren
	
	body.move_and_slide()
	#
	#body.set_skin("top_down")
	#body.scale = Vector2(0.2, 0.2) # evtl. statt hard coding Variable ship_sprite einbinden (
	## vgl.- level_base.gd)
	
