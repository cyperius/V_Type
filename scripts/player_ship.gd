class_name PlayerShip extends CharacterBody2D

# ──────────────────────────────────────────────────────────────
#   SIGNALS (für Main/UI, statt direkte UI‑Zugriffe)
# ──────────────────────────────────────────────────────────────
signal player_died(player_id: int)
signal shield_toggled(player_id: int, active: bool)
signal player_ship_flight_mode_switch_initiated

# ──────────────────────────────────────────────────────────────
#   ENUMS / MODE / Global Variables
# ──────────────────────────────────────────────────────────────
enum FlightMode { LEFT_RIGHT, RIGHT_LEFT, DOWN_UP, UP_DOWN, CIRCLE, FREE }
var mode : FlightMode
var circle_center_position := Vector2.ZERO
var circle_radius := 200.0
var face_circle_center := true
var angle := 0.0
var angular_speed := 2.0
var zoom_factor : Vector2 = Vector2(1, 1)
var cooling_down := false


# ──────────────────────────────────────────────────────────────
#   Module (für Composition)
# ──────────────────────────────────────────────────────────────

@onready var circle_flight_module: CircleFlightModuleModul = %CircleFlightModule
@onready var auto_pilot_modul: Node2D = $AutoPilotModul
@onready var label: Label = $Label



# ──────────────────────────────────────────────────────────────
#   PLAYER PROPERTIES
# ──────────────────────────────────────────────────────────────
@export var player_id: int = 1
@export var max_speed: float = 600.0
var speed: float = max_speed
var boost_activated := false
@export var auto_forward_speed := 300.0 # 21.2.2026: hier soll der Wert der Exportvariable des Levels (camera_scroll_speed) verwendet werden 
@export var auto_thrust_enabled := false


@export var max_health: int = 600
var health: int							# in _ready() auf max_health gesetzt
@export var max_energy: int = 1000
var blue_energy: int					# in _ready() auf max_energy gesetzt
var score : int = 0


var damage_already_dealt := false # zur Verhinderung von Mehrfachtreffern bei "dynamic_damaging_areas"
var shield_is_activated := false
var player_is_slowed_down := false
var controls_are_reversed := false
@export var damage: int = 10
var player_is_dead := false
var spawn_position := Vector2.ZERO

@export var shield_energy_drain : float = 100
@export var boost_energy_drain : float = 20
@export var absorbing_factor : float = 0.0

# ──────────────────────────────────────────────────────────────
#   WEAPONS
# ──────────────────────────────────────────────────────────────
@export var primary_weapon: PackedScene
@export var secondary_weapon: PackedScene


# ──────────────────────────────────────────────────────────────
#   GRAPHICS / FX / COLLISIONS
# ──────────────────────────────────────────────────────────────

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ship_sprite: Sprite2D = %ship_sprite

@onready var camera = get_tree().current_scene.get_node("%Camera2D")
var screen_width : float
var screen_hight : float

@onready var level = get_tree().current_scene.get_node("LevelContainer")

var skins

# -- skins --
# -- neutral --

var player1_skin = preload("res://assets/graphic_elements/player/p1_ship_sideways_neutral.png")
var player4_skin = preload("res://assets/graphic_elements/player/p4_gray_arrow_sideways_neutral.png")
var player3_skin = preload("res://assets/graphic_elements/player/p3_neutral_exportiert.png")
var player2_skin = preload("res://assets/graphic_elements/player/p2_ship_gold_sideways_neutral.png")
var player5_skin = preload("res://assets/graphic_elements/player/p5_white_gray_arrow_sideways_neutral.png")

# -- raising --
var player1_raising_skin = preload("res://assets/graphic_elements/player/p1_ship_sideways_bauchlage.png")
var player2_raising_skin = preload("res://assets/graphic_elements/player/p2_ship_gold_sideways_bauchlage.png")
var player3_raising_skin = preload("res://assets/graphic_elements/player/p3_bauchlage_exportiert.png")
var player4_raising_skin = preload("res://assets/graphic_elements/player/p4_gray_arrow_sideways_bauchlage.png")
var player5_raising_skin = preload("res://assets/graphic_elements/player/p5_white_gray_arrow_sideways_bauchlage Kopie 2.png")

# -- sinking("diving") --
var player1_diving_skin = preload("res://assets/graphic_elements/player/p1_ship_sideways_rueckenlage.png")
var player2_diving_skin = preload("res://assets/graphic_elements/player/p2_ship_gold_sideways_rueckenlage.png")
var player3_diving_skin = preload("res://assets/graphic_elements/player/p3_sideways_rueckenlage.png")
var player4_diving_skin = preload("res://assets/graphic_elements/player/p4_gray_arrow_sideways_rueckenlage.png")
var player5_diving_skin  = preload("res://assets/graphic_elements/player/p5_white_gray_arrow_sideways_rueckenlage.png")

# -- top down --
var player1_top_down = preload("res://assets/graphic_elements/player/p1_space_ship_top_down.png")
var player2_top_down = preload("res://assets/graphic_elements/player/p2_golden_ship.png")
var player3_top_down = preload("res://assets/graphic_elements/player/p3_topdown_gross.png")
var player4_top_down = preload("res://assets/graphic_elements/player/p4_ship_top_down.png")
var player5_top_down = preload("res://assets/graphic_elements/player/p5_white_gray_arrow_topdown_gross.png")


@onready var ship_area: Area2D = %ShipArea
@onready var just_been_hit_timer: Timer = %BeenHitTimer
@onready var _particles_shield: GPUParticles2D = %ParticlesShield
@onready var _shield_collision_shape: CollisionShape2D = %ShieldCollisionShape2D2
@onready var body_collision_shape_1: CollisionShape2D = $BodyCollisionShape1
@onready var body_collision_shape_2: CollisionShape2D = $BodyCollisionShape2

# effects
var hit_scene: PackedScene = preload("res://game_world/hit_animation.tscn")
var explosion_scene: PackedScene = preload("res://game_world/explosion_animation.tscn")

# Kollisions-Layer/Masken-Backup für Death/Revive Roundtrip
var _backup_collision_layer: int
var _backup_collision_mask: int


# visueller Status (z. B. fürs Blinken)
var default_player_state := Color(1, 1, 1)
var current_player_state := default_player_state
var health_ratio := 1.0



# ──────────────────────────────────────────────────────────────
#   READY
# ──────────────────────────────────────────────────────────────
func _ready() -> void:
	# HINWEIS: Registrierung passiert in Main.gd (Global.register_player(...)),
	# damit wir keine Doppel-Registrierung haben.
	
	label.text = ("P" + str(player_id))
	circle_flight_module.setup(self)
	print(player_id, " is my player_id")
	# Stats initial setzen (Export-Werte aus dem Inspector werden respektiert)
	health = max_health
	blue_energy = max_energy
	

	skins = [ # die keys der level1 Dictionaries entsprechen der jeweiligen player_id
		{"looks": {"neutral": player1_skin, "rising": player1_raising_skin, "sinking": player1_diving_skin, "top_down": player1_top_down, "scale": Vector2(0.7, 0.7)}},
		{"looks": {"neutral": player2_skin, "rising": player2_raising_skin, "sinking": player2_diving_skin, "top_down": player2_top_down, "scale": Vector2(0.7, 0.7)}},
		{"looks": {"neutral": player3_skin, "rising": player3_raising_skin, "sinking": player3_diving_skin, "top_down": player3_top_down, "scale": Vector2(0.75, 0.75)}},
		{"looks": {"neutral": player4_skin, "rising": player4_raising_skin, "sinking": player4_diving_skin, "top_down": player4_top_down, "scale": Vector2(0.75, 0.75)}},
		{"looks": {"neutral": player5_skin, "rising": player5_raising_skin, "sinking": player5_diving_skin, "top_down": player5_top_down, "scale": Vector2(0.8, 0.8)}},
		]
	
	# Kollisions-Backup sichern (für Death/Revive)
	_backup_collision_layer = collision_layer
	_backup_collision_mask = collision_mask

	# Schild-Kollision initial aus
	_shield_collision_shape.disabled = true
	
	## Circle-Mode Startwinkel und skin / bleibt aktuell 12.12.25 23.18 wirkungslos
	#if mode == FlightMode.CIRCLE:
		#var offset := global_position - circle_center_position
		#angle = offset.angle()
		#ship_sprite.texture = skins[player_id-1]["looks"]["top_down"]
	
	# DOWN_UP Mode skin -> == FlightMode scheint in der ready Funktion nciht zu funktionieren
	# -> Timing Problem
	if mode == FlightMode.DOWN_UP:
		set_skin("top_down")
		#ship_sprite.texture = skins[player_id-1]["looks"]["top_down"]
		#ship_sprite.scale = skins[player_id-1]["looks"]["scale"]

	# Initiale Stats an Main/UI melden
	#_emit_stats()
	

func connect_signals() -> void:
	print("connecte signals")
	level = GameManager.current_level_node # 5.4.26: falls fehler: var level := ...
	just_been_hit_timer.timeout.connect(_on_just_been_hit_timer_timeout)
	ship_area.area_entered.connect(_on_ship_area_entered)
	if level.has_signal("zoom_requested"):
		print("see the signal...")
		level.zoom_requested.connect(_on_zoom_requested)
	if level.has_signal("flight_mode_switch_initiated"):
		level.flight_mode_switch_initiated.connect(_on_flight_mode_switch_initiated)
	if level.has_signal("player_placement_initiated"):
		level.player_placement_initiated.connect(_on_player_placement_initiated)
	
		

func _on_player_placement_initiated()-> void:
	print("Player initiated signal received")
	circle_flight_module.setup(self)
	# Startwerte für CircleFlightMode ans Modul weitergeben
	

func set_skin(mode: String) -> void:
	ship_sprite.scale = skins[player_id-1]["looks"]["scale"]
	ship_sprite.texture = skins[player_id-1]["looks"][mode]
	body_collision_shape_1.scale = skins[player_id-1]["looks"]["scale"]
# ──────────────────────────────────────────────────────────────
#   PROCESS / INPUT
# ──────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if player_is_dead:
		# Revive ist eine Spielentscheidung → Taste „revive“ als Beispiel
		if Input.is_action_just_pressed("revive"):
			revive()
		return

	if Input.is_action_just_pressed("status_report"):
		status_report()

	# Boost
	if Input.is_action_just_pressed("p%d_accelerate" % player_id):
		_set_boost(true)
	if Input.is_action_just_released("p%d_accelerate" % player_id):
		_set_boost(false)
	if boost_activated:
		_drain_energy_per_sec(boost_energy_drain, delta)

	# Schild
	if Input.is_action_just_pressed("p%d_shield" % player_id):
		activate_shield()
	if Input.is_action_just_released("p%d_shield" % player_id):
		deactivate_shield()
	if shield_is_activated:
		_drain_energy_per_sec(shield_energy_drain, delta)
		_particles_shield.amount_ratio = float(blue_energy) / float(max_energy)
		if blue_energy <= 0:
			blue_energy = 0
			deactivate_shield()
		#_emit_stats()  # UI live halten

	
	if Input.is_action_just_pressed("p%d_primary_weapon" % player_id):
		shoot_weapon(primary_weapon, player_id)
	if Input.is_action_just_pressed("p%d_secondary_weapon" % player_id):
		shoot_weapon(secondary_weapon, player_id)


func _physics_process(delta: float) -> void:
	if player_is_dead:
		velocity = Vector2.ZERO
		return
	
	if not auto_pilot_modul.autopilot_is_on:
		match mode:
			FlightMode.LEFT_RIGHT:
				_physics_left_right_move(delta)
			FlightMode.CIRCLE:
				circle_flight_module.physics_update(delta) # <-- Modul übernimmt
			FlightMode.DOWN_UP:
				_physics_left_right_move(delta)
			# Bewegung je nach Modus
	#else:
		#print("autopilot is on..... autopilot is on...")
	

# ──────────────────────────────────────────────────────────────
#   MOVEMENT
# ──────────────────────────────────────────────────────────────

func _on_flight_mode_switch_initiated() -> void:
	player_ship_flight_mode_switch_initiated.emit()

func _physics_left_right_move(delta: float) -> void:
	var direction := Vector2.ZERO
	if controls_are_reversed:
		direction.x = Input.get_axis("p%d_right" % player_id, "p%d_left" % player_id)
		direction.y = Input.get_axis("p%d_down" % player_id, "p%d_up" % player_id)
	else:
		direction.x = Input.get_axis("p%d_left" % player_id, "p%d_right" % player_id)
		direction.y = Input.get_axis("p%d_up" % player_id, "p%d_down" % player_id)
	
	if mode == FlightMode.LEFT_RIGHT:
		if direction.y < 0:
			set_skin("rising")
		elif direction.y > 0:
			set_skin("sinking")
		else:
			set_skin("neutral")
	
	if auto_thrust_enabled:
		velocity = direction * speed + auto_forward_speed * Vector2(1, 0)
	else:
		velocity = direction * speed
	move_and_slide()
	

	# Wenn du an einer Wand klebst: Geschwindigkeit in Wandrichtung entfernen
	for collision_nr in range(get_slide_collision_count()):
		var collision := get_slide_collision(collision_nr)
		var normal := collision.get_normal()
		# Entferne den Anteil der velocity, der in die Wand zeigt
		if velocity.dot(normal) < 0.0:
			velocity = velocity.slide(normal)
	

	# Kamerahilfsfunktion des Autoloads "CameraUtilities" nutzen, mit dem 
	# aktuellen viewport als Argument (get_viewport())
	var visible_rect := CameraUtilities.get_visible_world_rect(get_viewport())
	var clamped_global := global_position # erst die Variable "clamed_global" kreieren und dann ihre
	# x bzw. y Properties clampen auf die Werte des erhaltenen visible_rect 
	clamped_global.x = clampf(clamped_global.x, visible_rect.position.x, visible_rect.position.x + visible_rect.size.x)
	clamped_global.y = clampf(clamped_global.y, visible_rect.position.y, visible_rect.position.y + visible_rect.size.y)
	global_position = clamped_global


# ──────────────────────────────────────────────────────────────
#   COMBAT / HIT / SHIELD
# ──────────────────────────────────────────────────────────────
func _on_ship_area_entered(other: Area2D) -> void:
	if "hit_effect" in other:
		_apply_effect_by_name(str(other.hit_effect))
	
	# Absicherung gegen Mehrfachschden, bei dynamischen collsionshapes, könnte
	# theoretsich für alle "others" geprüft werden, aber lasse er voresrt mal
	# so, als Erinnerung, wieso es nötig wurde
	if other.is_in_group("dynamic_damaging_areas"):
		if damage_already_dealt:
			return
		damage_already_dealt = true  # sofort setzen, bevor Schaden übergeben wird
	
	# Damage
	if "damage" in other:
		var dmg: int = int(other.damage)
		# i-Frame Schutz sofort aktivieren, unabhängig vom Schild-Status
		# verhindert dass z.B. eine wachsende Explosion mehrfach in aufeinanderfolgenden
		# Frames trifft
		
		if shield_is_activated:
			if other.is_in_group("projectiles"):
				shield_absorbing(dmg * absorbing_factor)  # Schild „heilt" Energie um Anteil des Schadens
			elif other.is_in_group("enemies") or other.is_in_group("obstacles"):
				_change_energy(-dmg)
		else:
			ship_area.collision_mask = 0
			ship_area.collision_layer = 0
			player_is_hit(dmg)

	
func player_is_hit(taken_damage: int) -> void:
	_change_health(-taken_damage)
	calculate_damage_state()
	if health <= 0:
		handle_player_death()
	else:
		_do_been_hit_blink()
		just_been_hit_timer.start()

func calculate_damage_state() -> void:
	health_ratio = float(health) / float(max_health)

func _do_been_hit_blink() -> void:
	var t := create_tween()
	t.tween_property(self, "modulate", Color(1, 0, 0), 1).set_trans(6).from_current()
	t.set_loops(1)

func _on_just_been_hit_timer_timeout() -> void:
	# Nach dem i-Frames-Blinken Kollisionswerte wiederherstellen
	modulate = current_player_state
	ship_area.collision_mask = _backup_collision_mask
	ship_area.collision_layer = _backup_collision_layer
	damage_already_dealt = false # Absicherung für die dynamic_damage_areas wieder resetten

# Schild
func activate_shield() -> void:
	if shield_is_activated or blue_energy <= 0:
		return
	_particles_shield.emitting = true
	shield_is_activated = true
	_shield_collision_shape.disabled = false
	emit_signal("shield_toggled", player_id, true)


func deactivate_shield() -> void:
	if not shield_is_activated:
		return
	_particles_shield.emitting = false
	shield_is_activated = false
	_shield_collision_shape.disabled = true
	emit_signal("shield_toggled", player_id, false)


func shield_absorbing(absorbed_damage: int) -> void:
	_change_energy(+absorbed_damage)


# boost
func _set_boost(active: bool) -> void:
	#if boost_activated == active:
		#return
	boost_activated = active
	if active:
		speed *= 1.8
		angular_speed *= 1.8
	else:
		speed /= 1.8
		angular_speed /= 1.8

# ──────────────────────────────────────────────────────────────
#   WEAPONS
# ──────────────────────────────────────────────────────────────
func shoot_weapon(weapon: PackedScene, player_id : int) -> void:
	if not weapon:
		return
	# hier gewünschtenfalls waffenspezifische Cool_down Phase integrieren?
	var projectile = weapon.instantiate()

	# Eigentümer setzen (robust, je nach Projektil-Implementierung)
	if "owner_id" in projectile:
		# print("(player_ship.gd): owner id in projectil!")
		projectile.owner_id = player_id # beim abfeuern, wird also die owner_id dem Schuss mitgegeben
	elif projectile.has_method("set_owner_id"):
		projectile.set_owner_id(player_id)

	# Position vom Gunpoint
	var gunpoint := %Gunpoint
	projectile.global_position = gunpoint.global_position if gunpoint else global_position

	# In Szene einfügen
	var root := get_tree().current_scene
	if root:
		root.add_child(projectile)
	else:
		add_child(projectile)

	if projectile.has_method("fire"):
		projectile.fire()
		await get_tree().create_timer(1.0).timeout
		#cooling_down = false


# ──────────────────────────────────────────────────────────────
#   EFFECTS (Reverse, Slow)
# ──────────────────────────────────────────────────────────────
func _apply_effect_by_name(effect: String) -> void:
	var table := {
		"reverse_controls": _apply_reverse_control,
		"slow": _apply_slow
	}
	if table.has(effect):
		table[effect].call()

func _apply_reverse_control() -> void:
	if controls_are_reversed:
		return
	controls_are_reversed = true
	await get_tree().create_timer(5.0).timeout
	controls_are_reversed = false

func _apply_slow() -> void:
	if player_is_slowed_down:
		return
	player_is_slowed_down = true
	speed /= 2.0
	await get_tree().create_timer(1.5).timeout
	speed *= 2.0
	await get_tree().create_timer(1.0).timeout
	player_is_slowed_down = false

# ──────────────────────────────────────────────────────────────
#   LIFE / RESPAWN (ID‑basiert mit Global)
# ──────────────────────────────────────────────────────────────
func handle_player_death() -> void:
	print("Spieler %d ist gestorben!" % player_id)

	# Logisch deaktivieren
	visible = false
	set_process(false)
	set_physics_process(false)
	player_is_dead = true

	# Schild sicher aus
	deactivate_shield()

	# Explosion an Root hängen (läuft weiter, auch wenn dieses Node gestoppt ist)
	var explosion = explosion_scene.instantiate()
	get_tree().current_scene.add_child(explosion)
	explosion.global_position = global_position

	# kurz warten nach Zerstörung bis diese weitergeleitet wird
	await get_tree().create_timer(4).timeout

	# Jetzt erst als zerstört markieren → triggert GameOver/Pausing erst NACH der Explosion
	Global.mark_player_destroyed(player_id)

	# Event für Außenwelt
	emit_signal("player_died", player_id)


func revive() -> void:
	print("Spieler %d wird wiederbelebt!" % player_id)

	# Werte zurücksetzen
	global_position = spawn_position
	visible = true
	set_process(true)
	set_physics_process(true)
	player_is_dead = false
	health = max_health
	blue_energy = max_energy
	modulate = default_player_state

	# Kollisionswerte zuverlässig wiederherstellen
	collision_layer = _backup_collision_layer
	collision_mask = _backup_collision_mask

	# Global: ID aus „zerstört“ entfernen (triggert Signale/roster_changed)
	Global.revive_player(player_id)

	# UI updaten
	_emit_stats()

# ──────────────────────────────────────────────────────────────
#   UTILS (Stats & Energie/Health Änderungshelfer)
# ──────────────────────────────────────────────────────────────
func _emit_stats() -> void:
	GameManager._update_player_ui(player_id)
	

func _change_health(delta_hp: int) -> void:
	health = clamp(health + delta_hp, 0, max_health)
	_emit_stats()
#
func _change_energy(delta_energy: int) -> void:
	blue_energy = clamp(blue_energy + delta_energy, 0, max_energy)
	_emit_stats()

func _drain_energy_per_sec(rate: float, delta: float) -> void:
	if blue_energy <= 0:
		return
	var drain := rate * delta
	if drain != 0:
		_change_energy(-drain)


func _on_zoom_requested(zx: float, zy: float, t: int) -> void:
	print("player_ship received zoom signal)")
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(self, "zoom_factor:x", zx, t)
	tween.tween_property(self, "zoom_factor:y", zy, t)


# ──────────────────────────────────────────────────────────────
#   DEBUG
# ──────────────────────────────────────────────────────────────
func status_report() -> void:
	print("player_id:", player_id, " pos:", global_position, "screensize: ", get_viewport_rect().size, " hp:", health, " energy:", blue_energy)
	


func _on_animated_sprite_2d_animation_finished() -> void:
	print("animated_sprite_finished")
	animated_sprite.hide()
	ship_sprite.show()
	
	
func _change_flight_state() -> void:
	auto_pilot_modul.autopilot_is_on = true
	ship_sprite.hide()
	animated_sprite.show()
	animated_sprite.play("p" + str(player_id) + "_sideways_to_top_down")
