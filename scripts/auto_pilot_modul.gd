class_name AutoPilotModul extends Node2D

signal autopilot_activated

var autopilot_is_on := false

var new_target_destination : Vector2
var new_target_rotation : float
var direction : Vector2
var speed : float
var controlled_unit : CharacterBody2D


# ──────────────────────────────────────────────────────────────
# PROPERTIES {von CircleFlightModus übernommen)
# ──────────────────────────────────────────────────────────────
var player_id: int
var angle: float = 0.0
var angular_speed: float = 2.0
var circle_radius: float = 200.0
var circle_center_position := Vector2.ZERO
var face_circle_center := true

# Referenz auf den CharacterBody2D (wird von PlayerShip gesetzt)
var body: CharacterBody2D


# ──────────────────────────────────────────────────────────────
# SETUP (von PlayerShip aufrufen statt _ready)
# ──────────────────────────────────────────────────────────────

func setup(owner_body: CharacterBody2D) -> void:
	body = owner_body
	# Direkt vom Body lesen - keine Doppelzuweisung nötig
	player_id = body.player_id
	circle_center_position = body.circle_center_position
	circle_radius = body.circle_radius
	angular_speed = body.angular_speed
	face_circle_center = body.face_circle_center



func _ready() -> void:
	controlled_unit = get_parent()
	print("controlled_unit is: ", controlled_unit)
	if "speed" in controlled_unit:
		speed = controlled_unit.speed / 3
	if "direction" in controlled_unit:
		direction = controlled_unit.direction
		
		

func _set_new_target_destination(target_destination: Vector2, target_rotation: float, activate_autopilot: bool) -> void:
	print("receoced target_destination: ", target_destination)
	new_target_destination = target_destination
	new_target_rotation = target_rotation
	print("new_target_destination is..: ", new_target_destination)
	print("player ", controlled_unit.player_id, " : target_rotation: ", target_rotation)
	direction = controlled_unit.global_position.direction_to(new_target_destination)
	print("direction: ", direction)
	autopilot_is_on = activate_autopilot
	if autopilot_is_on:
		emit_signal("autopilot_activated") # aktuell 5.4.2026 11:48 noch nicht genutzt
	
	
func _physics_process(delta: float) -> void:
	if autopilot_is_on:
		#print("autopilot_target_destination :", new_target_destination)
		#print("controlled_unit_global_position: ", controlled_unit.global_position)
		#print("autopilot is on... NOW :", autopilot_is_on)
		
		# Zielposition erreichen:
		var distance_difference = new_target_destination.distance_to(controlled_unit.global_position)
		if distance_difference > 5:
			direction = controlled_unit.global_position.direction_to(new_target_destination) # muss in process Funktion laugfend angepasst werden
			controlled_unit.velocity = direction * speed * delta # so führt das aber noch zum Zittern am Zielort, es fehlt die Rückmeldung..
			controlled_unit.global_position += controlled_unit.velocity # wenn das Ziel erreicht ist, Prüfung mit vector2.approx(..) hat nicht funktioniert
			
		# Zielausrichtung erreichen:
		var rotation_difference = abs(controlled_unit.rotation - new_target_rotation)
		if rotation_difference > 0.02: # Wert von rotation geht bis Pi (oder 2 Pi?)
			if controlled_unit.rotation > new_target_rotation:
				controlled_unit.rotation -= (controlled_unit.rotation - new_target_rotation) * delta
			if controlled_unit.rotation < new_target_rotation:
				controlled_unit.rotation += (new_target_rotation - controlled_unit.rotation) * delta
				
		if rotation_difference <= 0.02 and distance_difference <= 5:
			controlled_unit.circle_flight_module.setup(controlled_unit) # dem Circle
			# FlightModul die aktuellen daten durchgeben (evtl. kann da snoch etwas vereinafch werden..)
			autopilot_is_on = false
			#
		
		
