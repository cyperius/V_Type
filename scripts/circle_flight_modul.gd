class_name CircleFlightModuleModul extends Node


# ──────────────────────────────────────────────────────────────
# PROPERTIES
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


# ──────────────────────────────────────────────────────────────
# BEWEGUNGSLOGIK
# ──────────────────────────────────────────────────────────────
func physics_update(delta: float) -> void: # diese Funktion wird in der process_Function 
					#... des parent als lock_target_modul.phyics_update() aufgerufen
	
			var input_strength := Input.get_action_strength("p%d_right" % player_id) - Input.get_action_strength("p%d_left" % player_id)
			
			# 25.3.2026 - Aktive Steuerung: Physiksteuerung inkl. Kollsionsvorhersage und dann Stopp
			# Kein Input -> keine Bewegung (du bleibst exakt stehen)
			if is_equal_approx(input_strength, 0.0):
				body.velocity = Vector2.ZERO
				return

			# Naechster Winkel (noch NICHT uebernehmen)
			# Steuerung: rechts -> Uhrzeigersinn
			var next_angle := angle + input_strength * angular_speed * delta
			
			# Steuerung: rechts -> Gegenuhrzeigersinn
			#var next_angle := angle - input_strength * angular_speed * delta

			# Zielpunkt auf der Schiene (exakt Kreis)
			var next_offset := Vector2(cos(next_angle), sin(next_angle)) * circle_radius
			var next_position := circle_center_position + next_offset

			# Bewegung, die wir machen wuerden
			var motion := next_position - body.global_position

			# Testen, ob diese Bewegung kollidiert (ohne sie wirklich auszufuehren)
			var collision := body.move_and_collide(motion, true) # test_only = true

			if collision == null:
				# Frei -> Winkel uebernehmen und exakt auf den Kreis setzen
				angle = next_angle
				body.global_position = next_position
			else:
				# Blockiert -> Winkel nicht aendern (du "klemmst" an der Wand)
				body.velocity = Vector2.ZERO


			if face_circle_center:
				# Optik: nach innen ausrichten (auch wenn blockiert)
				body.rotation = angle + PI
			else:
				# nach aussen ausrichten
				body.rotation = angle + 2*PI

		## 25.3.2026 -aktuell nicht aktiv: einfache Variante ohne Physik-Steuerung
			#angle += input_strength * angular_speed * delta
			#var offset := Vector2(cos(angle), sin(angle)) * circle_radius
			#global_position = circle_center_position + offset
			#rotation = angle 
			
			
			
		# --------- Setup im playership.gd, bzw wienem parent der CharacterBody2D ist ------ 
		## in PlayerShip.gd
		#@onready var circle_flight_module: CircleFlightModule = $CircleFlightModule
		#
		#func _ready() -> void:
			## ... bestehender Code ...
			#circle_flight_module.setup(self, player_id)
			## Startwerte ans Modul weitergeben
			#circle_flight_module.circle_center_position = circle_center_position
			#circle_flight_module.circle_radius = circle_radius
			#circle_flight_module.angular_speed = angular_speed
			#circle_flight_module.face_circle_center = face_circle_center
		#
		#func _physics_process(delta: float) -> void:
			#if player_is_dead:
				#velocity = Vector2.ZERO
				#return
		#
			#match mode:
				#FlightMode.LEFT_RIGHT:
					#_physics_left_right_move(delta)
				#FlightMode.CIRCLE:
					#circle_flight_module.physics_update(delta) # <-- Modul übernimmt
				#FlightMode.DOWN_UP:
					#_physics_left_right_move(delta)
