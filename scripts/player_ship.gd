# Die Klasse erbt von Area2D, was Kollisionserkennung ermöglicht
class_name player_ship extends Area2D

signal hit_effect_triggered(effect)

# ─── NEU: Modi für das Spieler‐Schiff ──────────────────────────────────────────
enum PlayerMode {
	FREE,
	CIRCLE
}
# Wird vom Level‐Script gesetzt (siehe Erklärung unten)
var mode := PlayerMode.FREE
# Für Circle-Mode: Zentrum und Radius (ebenfalls vom Level‐Script zuweisen)
var circle_center_position := Vector2.ZERO
var circle_radius := 200.0
# Interne Variable: aktueller Winkel auf dem Kreis
var angle := 0.0
# Wie schnell sich der Winkel ändert (Radiant pro Sekunde)
var angular_speed := 2.0
# ───────────────────────────────────────────────────────────────────────────────

# Aktuelle Bewegungsrichtung und -geschwindigkeit (x und y Komponenten)
var velocity := Vector2(240, 240)
var default_player_state = Color(1, 1, 1)
var current_player_state = default_player_state 

@export var player_id : int = 1

# @export macht diese Variablen im Godot Editor sichtbar und einstellbar
# PackedScene ist ein Typ für vorbereitete Szenen (wie unsere Laser-Projektile)
@export var laser_beam: PackedScene    # Szene für den normalen Laser
@export var laser_blast: PackedScene   # Szene für den starken Laser

# Grundgeschwindigkeit des Raumschiffs (Pixel pro Sekunde)
@export var max_speed := 600
var speed := max_speed
var boost_activated := false

@export var max_health: int = 600
@onready var health := max_health
@export var blue_energy : int = 1000
var shield_is_activated := false
var player_is_slowed_down := false
var controls_are_reversed := false
@export var damage: int = 10
@export var game_over: PackedScene        # Game Over Szene
@onready var just_been_hit_timer := %BeenHitTimer
@onready var hit_scene : PackedScene = preload("res://scenes/hit.tscn")
# Schild um das Schiff mittels PGPUParticles, kann vom Spieler aktiviert werden
@onready var _particles_shield: GPUParticles2D = %ParticlesShield
@onready var _shield_collision_shape: CollisionShape2D = %ShieldCollisionShape2D2
# health_ratio bestimmen um für Farbgebung und allenfalls weitere Effekte zu verwenden
@onready var health_ratio := 1.0

# Diese Variablen speichern die aktiven Waffen
var primary_weapon: PackedScene        # Hauptwaffe
var secondary_weapon: PackedScene      # Sekundärwaffe
var projectiles := []                  # Liste aller aktiven Projektile



# Diese Funktion wird beim Start der Szene automatisch ausgeführt
func _ready():
	# Sobald das Spieler-Schiff instanziiert und bereit ist, setzen wir den globalen Verweis darauf.
	# Damit können andere Scripts jederzeit über Global.player_ship darauf zugreifen.
	Global.player_ship = self

	# Wir setzen zusätzlich eine Referenz auf den Sprite des Schiffs (z. B. für Farbänderungen oder Animationen)
	Global.player_sprite = get_node("ship_sprite")  # Node-Name muss genau stimmen!

	# Timer-Signal verbinden – z. B. um nach einem Treffer kurz unverwundbar zu sein oder zu blinken
	just_been_hit_timer.timeout.connect(_on_just_been_hit_timer_timeout)
	# Signal "hit_effect_triggered" verbinden
	hit_effect_triggered.connect(_on_hit_effect_triggered)
	# Debug-Ausgabe: aktueller Health-Wert (wenn health vorher korrekt initialisiert ist)
	print(health)

	# Weist den Waffen-Variablen die entsprechenden Szenen zu
	primary_weapon = laser_beam
	secondary_weapon = laser_blast
	area_entered.connect(_on_area_entered)
	
	# Collisionserkennung des Schilds zu Beginn ausschalten
	_shield_collision_shape.disabled = false
	

	# ─── NEU: Initialisierung für Circle-Mode ───────────────────────────────
	if mode == PlayerMode.CIRCLE:
		# Wenn der Level-Code vor _ready() bereits circle_center_position gesetzt hat,
		# können wir anhand der aktuellen Position den Startwinkel bestimmen:
		var offset := global_position - circle_center_position
		angle = offset.angle()
		
	# ────────────────────────────────────────────────────────────────────────

# Diese Funktion wird jeden Frame ausgeführt
# delta ist die Zeit seit dem letzten Frame in Sekunden
func _process(delta: float) -> void:
	
	if Input.is_action_just_pressed("status_report"):
		status_report()
		
		# Beschleunigung: Erhöht die Geschwindigkeit um in beiden Flugmodi
	if Input.is_action_just_pressed("p%d_accelarate" % player_id):
		speed *= 1.8
		angular_speed *= 1.8
		boost_activated = true
		
	# Wenn Beschleunigung losgelassen wird, zurück zur normalen Geschwindigkeit
	if Input.is_action_just_released("p%d_accelarate" % player_id):
		speed /= 1.8
		angular_speed /= 1.8
		boost_activated = false
		
	if boost_activated:
		blue_energy -= 50 * delta
		get_tree().current_scene.ui.energy.text = "Energy: " + str(blue_energy)
	
	# aktiviert den Schild -> braucht Energie, absorbiert Schüsse
	if Input.is_action_just_pressed("p%d_shield" % player_id) and blue_energy > 0:
		activate_shield()
	# Wenn Taste losgelassen, Schild deaktivieren
	if Input.is_action_just_released("p%d_shield" % player_id):
		deactivate_shield()
	# Code der unabhängig vom PlayerMode gelten soll
	# vorübergehend zwecks debugging im process Funktion laufend upgedatet
	#get_tree().current_scene.ui.health.text = "Health: " + str(health)
	if shield_is_activated:
		# bei aktiviertem Schild wird laufend Energie verbraucht...
		blue_energy -= 300 * delta
		# dies wird in der UI angezeigt
		get_tree().current_scene.ui.energy.text = "Energy: " + str(blue_energy)
		# durch die Verknüpfung von Schildenergie mt Particle_amount wird die 
		# die Stäreke des Schilds visualisiert
		_particles_shield.amount_ratio = float(blue_energy) / 1000.0
		print("amount_ratio: ", _particles_shield.amount_ratio, "blue Energy: ", blue_energy)
		# und die Schild_collision_shape aktiveirt
		_shield_collision_shape.disabled = false
		if blue_energy <= 0:
			blue_energy = 0
			deactivate_shield()
	else:
		# Schild_collision_shape deaktivieren, damit nur die player_ship \
		# collision_shape Treffer registriert
		_shield_collision_shape.disabled = true
	
		# Überprüft Waffeneingaben und löst entsprechende Waffen aus
	if Input.is_action_just_pressed("p%d_primary_weapon" % player_id):
		if blue_energy < 20:
			return
		blue_energy -= 20
		get_tree().current_scene.ui.energy.text = "Energy: " + str(blue_energy)
		shoot_weapon(primary_weapon)
		
	if Input.is_action_just_pressed("p%d_secondary_weapon" % player_id):
		shoot_weapon(secondary_weapon)
		
	# Unterscheidung von PlayerMode
	match mode:
		PlayerMode.FREE:
			_process_horizontal(delta)
		PlayerMode.CIRCLE:
			_process_circle(delta)
		
		
# ─── FREE-Mode: Standard Bewegungs- & Schusslogik ─────────────────
func _process_horizontal(delta: float) -> void:
	# Bewegungssteuerung des Schiffs
	var direction := Vector2(0, 0)
	if controls_are_reversed:
		direction.x = Input.get_axis("p%d_right" % player_id, "p%d_left" % player_id)  # verkehrt
		direction.y = Input.get_axis("p%d_down" % player_id, "p%d_up" % player_id)            # verkehrt
		print("links ist rechts und oben ist unten")
	else:
		direction.x = Input.get_axis("p%d_left" % player_id, "p%d_right" % player_id)  # Links/Rechts
		direction.y = Input.get_axis("p%d_up" % player_id, "p%d_down" % player_id)            # Hoch/Runter

	# Grösse des Fensters erfassen (zwecks Bewegungsbegrenzung)
	var screensize := get_viewport_rect().size

	# Berechnet die aktuelle Geschwindigkeit
	velocity = direction * speed
	# Aktualisiert die Position des Schiffs
	position += velocity * delta
	position.x = clampf(position.x, 0, screensize.x)
	position.y = clampf(position.y, 0, screensize.y)


# ─── CIRCLE-Mode: Schiff bewegt sich auf Kreislinie, immer nach außen gerichtet ───
func _process_circle(delta: float) -> void:
	# 1. Eingabe: Links/Rechts ändern den Winkel
	var input_strength := Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	angle += input_strength * angular_speed * delta

	# 2. Neue Position auf dem Kreis berechnen
	var offset := Vector2(cos(angle), sin(angle)) * circle_radius
	global_position = circle_center_position + offset

	# 3. Rotation setzen: Schiff zeigt immer radial nach außen
	rotation = angle + PI


func _on_area_entered(area_that_entered: Area2D) -> void:
	if "hit_effect" in area_that_entered:
			emit_signal("hit_effect_triggered", area_that_entered.hit_effect)
	if "damage" in area_that_entered:
		var potential_damage_inflicted : int = area_that_entered.damage
		if shield_is_activated == true:
			if area_that_entered.is_in_group("projectiles"):
				shield_absorbing(potential_damage_inflicted)
			if area_that_entered.is_in_group("enemies"):
				blue_energy -= potential_damage_inflicted
		else:
			print("Ich bin getroffen")
			collision_mask = 0
			collision_layer = 0
			player_is_hit(potential_damage_inflicted)
		if area_that_entered.is_in_group("projectiles"):
			var hit = hit_scene.instantiate()
			add_child(hit)
			hit.scale = Vector2(15, 15)
			hit.global_position = Vector2(area_that_entered.global_position.x -45, area_that_entered.global_position.y)
			area_that_entered.queue_free()
		

func player_is_hit(damage: int):
	print("health: ", health)
	health -= damage
	get_tree().current_scene.ui.health.text = "Health: " + str(health)
	print("damage: ", damage, "ergo new health: ", health)
	calculate_damage_state()
	if health <= 0:
		hide()
		# Spieler kann nicht mehr schießen oder sich bewegen,
		# weil der GameManager den Baum pausiere wird.
		GameManager.set_state(GameManager.STATE_GAME_OVER)

	else:	
		#current_player_state = Color(1, health_ratio, health_ratio)
		#modulate = current_player_state
		do_the_been_hit_blinking()
		just_been_hit_timer.start()


func calculate_damage_state():
	# Berechnung des aktuellen Gesundheitszustand im Verhältnis zur maximalen Gesundheit 
	health_ratio = float(health) / float(max_health)
	# zunehmende Rotverfärnbung des player-ships mit abnehmendem Gesundheitszustand
	
	
func do_the_been_hit_blinking():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 0, 0), 1).set_trans(6).from_current()
	tween.set_loops(1)


func _on_just_been_hit_timer_timeout() -> void:
	print("ja. ich werde ausgelösat")
	modulate = current_player_state
	collision_mask = (1 << 2) | (1 << 3) | (1 << 4) | (1 << 5)
	collision_layer = 1
	# ("um die Ebenen 3, 4, 5 und 6 in deiner Collision-Maske wieder zu aktivieren, kannst du die Bit-Shift-Notation verwenden.")

#Schildfunktionen
func activate_shield():
	print("shield activated")
	_particles_shield.emitting = true
	# modulate = Color(0.27, 0.03, 0.87, 1.0)
	shield_is_activated = true
	

func shield_absorbing(absorbed_damage):
	blue_energy += absorbed_damage
	get_tree().current_scene.ui.energy.text = "Energy: " + str(blue_energy)
	

func deactivate_shield():
	print("shield deactivated")
	_particles_shield.emitting = false
	shield_is_activated = false
	# modulate = current_player_state
	

#Funktion zum Abfeuern einer Waffe
# weapon: PackedScene - Die Szene des Projektils, das abgefeuert werden soll
func shoot_weapon(weapon: PackedScene):
	if not weapon:
		print("Fehler: Keine Waffe zugewiesen!")
		return

	# Instanziere das Projektil
	var projectile_instance = weapon.instantiate()
	
	# Füge das Projektil der aktuellen Szene hinzu
	var current_scene = get_tree().current_scene
	if current_scene:
		current_scene.add_child(projectile_instance)
		#print("✅ Projektil erfolgreich zur Szene hinzugefügt!")
	else:
		print("Fehler: Keine aktuelle Szene gefunden!")
		return

	# Verwende den Gunpoint als Referenz für den Startpunkt des Schusses
	var gunpoint = $Gunpoint
	if gunpoint:
		projectile_instance.global_position = gunpoint.global_position
		#print("Projektil-Position (Gunpoint):", projectile_instance.global_position)
	else:
		# Fallback: Nutze die Schiffposition
		projectile_instance.global_position = global_position
		print("Gunpoint nicht gefunden, nutze Schiffposition:", projectile_instance.global_position)

	# Füge das Projektil der Liste aktiver Projektile hinzu
	projectiles.append(projectile_instance)

	# Rufe, falls vorhanden, die fire()-Methode des Projektils auf
	if projectile_instance.has_method("fire"):
		#print("Fire-Funktion wird aufgerufen!")
		projectile_instance.fire()
	else:
		print("Fehler: Projektil hat keine fire()-Methode!")


func status_report() -> void:
	print("player_global_position: ", global_position)


func _on_hit_effect_triggered(effect : String):
	var effect_table = {
		"reverse_controls" : _apply_reverse_control,
		"slow": _apply_slow
	}
	
	if effect_table.has(effect):
		effect_table[effect].call()
	else:
		print("Unbekannter Effekt: ", effect)
	

func _apply_reverse_control() -> void:
	print("Steuerung wird umgekehrt!")
	# Wenn der Effekt noch aktiv ist, kann der Spieler nicht erneut infiziert werden
	if controls_are_reversed:
		return
	# ansonsten: Steuerung umkehren
	controls_are_reversed = true
	print("steuerung umgedreht?")
	await get_tree().create_timer(5).timeout
	# nach Ablauf des Timers wieder auf normal stellen (allenfalls zusätzliche Immun-Zeit?)
	controls_are_reversed = false
	

func _apply_slow() -> void:
	if player_is_slowed_down:
		return
	else:
		print("Spieler wird verlangsamt.")
		player_is_slowed_down = true
		speed /= 2
		await get_tree().create_timer(1.5).timeout
		speed *= 2
		await  get_tree().create_timer(1).timeout
		player_is_slowed_down = false
	
