extends Area2D
class_name PlayerShip

# ──────────────────────────────────────────────────────────────
#   SIGNALS (für Main/UI, statt direkte UI‑Zugriffe)
# ──────────────────────────────────────────────────────────────
signal stats_changed(player_id: int, health: int, energy: int)
signal player_died(player_id: int)
signal shield_toggled(player_id: int, active: bool)

# ──────────────────────────────────────────────────────────────
#   ENUMS / MODE
# ──────────────────────────────────────────────────────────────
enum PlayerMode { FREE, CIRCLE }
var mode := PlayerMode.FREE
var circle_center_position := Vector2.ZERO
var circle_radius := 200.0
var angle := 0.0
var angular_speed := 2.0

# ──────────────────────────────────────────────────────────────
#   PLAYER PROPERTIES
# ──────────────────────────────────────────────────────────────
@export var player_id: int = 1
@export var max_speed: float = 600.0
var speed: float = max_speed
var boost_activated := false

@export var max_health: int = 600
var health # wird  in _ready-Funktion auf max_health Wert gesetzt
@export var max_energy: int = 1000
var blue_energy # analog zu health

var shield_is_activated := false
var player_is_slowed_down := false
var controls_are_reversed := false
@export var damage: int = 10
var player_is_dead := false
var spawn_position := Vector2.ZERO

# ──────────────────────────────────────────────────────────────
#   WEAPONS
# ──────────────────────────────────────────────────────────────
@export var laser_beam: PackedScene       # Hauptlaser
@export var laser_blast: PackedScene      # Starker Laser
var primary_weapon: PackedScene
var secondary_weapon: PackedScene
var projectiles := []

# ──────────────────────────────────────────────────────────────
#   GRAPHICS / FX / COLLISIONS
# ──────────────────────────────────────────────────────────────
@onready var ship_sprite: Sprite2D = %ship_sprite
@onready var player1_skin = preload("res://assets/graphic_elements/enemies/space_ship1.png")
@onready var player2_skin = preload("res://assets/graphic_elements/enemies/player2_ship.png")

@onready var just_been_hit_timer: Timer = %BeenHitTimer
@onready var hit_scene: PackedScene = preload("res://scenes/hit.tscn")
@onready var explosion_scene: PackedScene = preload("res://scenes/explosion_animation.tscn")
@onready var _particles_shield: GPUParticles2D = %ParticlesShield
@onready var _shield_collision_shape: CollisionShape2D = %ShieldCollisionShape2D2

# visueller Status (z. B. fürs Blinken)
var default_player_state := Color(1, 1, 1)
var current_player_state := default_player_state
var health_ratio := 1.0

# ──────────────────────────────────────────────────────────────
#   READY
# ──────────────────────────────────────────────────────────────
func _ready() -> void:
	# Registrierung zentral hier (Main ruft NICHT mehr register auf)
	Global.register_player(player_id, self, ship_sprite)

	# stats setzen (erst in -ready-Funktion, damit der Bezug auf den im Editor
	# gesetzten Wert für max_health (als @export Variable) funktioniert
	health = max_health
	blue_energy = max_energy
	
	# Skin
	if player_id == 2:
		ship_sprite.texture = player2_skin
		ship_sprite.scale = Vector2(1.5, 1.2)
	else:
		ship_sprite.texture = player1_skin

	# Signale
	just_been_hit_timer.timeout.connect(_on_just_been_hit_timer_timeout)
	area_entered.connect(_on_area_entered)

	# Schild-Kollision initial aus
	_shield_collision_shape.disabled = true

	# Waffen
	primary_weapon = laser_beam
	secondary_weapon = laser_blast

	# Circle-Mode Startwinkel
	if mode == PlayerMode.CIRCLE:
		var offset := global_position - circle_center_position
		angle = offset.angle()

	# Initiale Stats an Main/UI melden
	_emit_stats()

# ──────────────────────────────────────────────────────────────
#   PROCESS / INPUT
# ──────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if player_is_dead:
		if Input.is_action_just_pressed("revive"):
			revive()
		return

	if Input.is_action_just_pressed("status_report"):
		status_report()

	# Boost
	if Input.is_action_just_pressed("p%d_accelarate" % player_id):
		_set_boost(true)
	if Input.is_action_just_released("p%d_accelarate" % player_id):
		_set_boost(false)
	if boost_activated:
		_drain_energy_per_sec(50.0, delta)

	# Schild
	if Input.is_action_just_pressed("p%d_shield" % player_id):
		activate_shield()
	if Input.is_action_just_released("p%d_shield" % player_id):
		deactivate_shield()
	if shield_is_activated:
		_drain_energy_per_sec(300.0, delta)
		_particles_shield.amount_ratio = float(blue_energy) / float(max_energy)
		if blue_energy <= 0:
			blue_energy = 0
			deactivate_shield()
		_emit_stats()  # UI live halten

	# Waffen
	if Input.is_action_just_pressed("p%d_primary_weapon" % player_id):
		shoot_weapon(primary_weapon)
	if Input.is_action_just_pressed("p%d_secondary_weapon" % player_id):
		shoot_weapon(secondary_weapon)

	# Bewegung je nach Modus
	match mode:
		PlayerMode.FREE:
			_process_free_move(delta)
		PlayerMode.CIRCLE:
			_process_circle(delta)

# ──────────────────────────────────────────────────────────────
#   MOVEMENT
# ──────────────────────────────────────────────────────────────
func _process_free_move(delta: float) -> void:
	var direction := Vector2.ZERO
	if controls_are_reversed:
		direction.x = Input.get_axis("p%d_right" % player_id, "p%d_left" % player_id)
		direction.y = Input.get_axis("p%d_down" % player_id, "p%d_up" % player_id)
	else:
		direction.x = Input.get_axis("p%d_left" % player_id, "p%d_right" % player_id)
		direction.y = Input.get_axis("p%d_up" % player_id, "p%d_down" % player_id)

	var screensize := get_viewport_rect().size
	var velocity := direction * speed
	position += velocity * delta
	position.x = clampf(position.x, 0.0, screensize.x)
	position.y = clampf(position.y, 0.0, screensize.y)

func _process_circle(delta: float) -> void:
	var input_strength := Input.get_action_strength("p%d_right" % player_id) - Input.get_action_strength("p%d_left" % player_id)
	angle += input_strength * angular_speed * delta
	var offset := Vector2(cos(angle), sin(angle)) * circle_radius
	global_position = circle_center_position + offset
	rotation = angle + PI


# ──────────────────────────────────────────────────────────────
#   COMBAT / HIT / SHIELD
# ──────────────────────────────────────────────────────────────
func _on_area_entered(other: Area2D) -> void:
	# Effekt-Trigger (optional)
	if "hit_effect" in other:
		# Du hattest früher ein eigenes Signal – falls nötig, wieder verwenden
		# emit_signal("hit_effect_triggered", other.hit_effect)
		_apply_effect_by_name(str(other.hit_effect))

	# Damage
	if "damage" in other:
		var dmg: int = int(other.damage)
		if shield_is_activated:
			if other.is_in_group("projectiles"):
				shield_absorbing(dmg)  # Schild „heilt“ Energie um Schaden
			elif other.is_in_group("enemies"):
				_change_energy(-dmg)
		else:
			collision_mask = 0
			collision_layer = 0
			player_is_hit(dmg)

		# Treffer-Feedback bei Projektilen
		if other.is_in_group("projectiles"):
			var hit = hit_scene.instantiate()
			add_child(hit)
			hit.scale = Vector2(15, 15)
			hit.global_position = Vector2(other.global_position.x - 45, other.global_position.y)
			other.queue_free()

func player_is_hit(dmg: int) -> void:
	_change_health(-dmg)
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
	modulate = current_player_state
	collision_mask = (1 << 2) | (1 << 3) | (1 << 4) | (1 << 5)
	collision_layer = 1

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

# ──────────────────────────────────────────────────────────────
#   WEAPONS
# ──────────────────────────────────────────────────────────────
func shoot_weapon(weapon: PackedScene) -> void:
	if not weapon:
		return
	var projectile = weapon.instantiate()

	# Eigentümer setzen (robust, je nach Projektil-Implementierung)
	if "owner_id" in projectile:
		projectile.owner_id = player_id
	elif projectile.has_method("set_owner_id"):
		projectile.set_owner_id(player_id)

	# Position vom Gunpoint
	var gunpoint := $Gunpoint
	projectile.global_position = gunpoint.global_position if gunpoint else global_position

	# In Szene einfügen
	var root := get_tree().current_scene
	if root:
		root.add_child(projectile)
	else:
		add_child(projectile)

	projectiles.append(projectile)
	if projectile.has_method("fire"):
		projectile.fire()

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
#   LIFE / RESPAWN
# ──────────────────────────────────────────────────────────────
func handle_player_death() -> void:
	print("Spieler %d ist gestorben!" % player_id)
	visible = false
	set_process(false)
	set_physics_process(false)
	player_is_dead = true
	Global.destroyed_player_ships.append(self)

	var boom = explosion_scene.instantiate()
	get_tree().current_scene.add_child(boom)
	boom.global_position = global_position

	emit_signal("player_died", player_id)

func revive() -> void:
	print("Spieler %d wird wiederbelebt!" % player_id)
	global_position = spawn_position
	visible = true
	set_process(true)
	set_physics_process(true)
	player_is_dead = false
	health = max_health
	blue_energy = max_energy
	modulate = default_player_state
	_emit_stats()

# ──────────────────────────────────────────────────────────────
#   UTILS (Stats & Energie/Health Änderungshelfer)
# ──────────────────────────────────────────────────────────────
func _emit_stats() -> void:
	emit_signal("stats_changed", player_id, health, blue_energy)

func _change_health(delta_hp: int) -> void:
	health = clamp(health + delta_hp, 0, max_health)
	_emit_stats()

func _change_energy(delta_energy: int) -> void:
	blue_energy = clamp(blue_energy + delta_energy, 0, max_energy)
	_emit_stats()

func _drain_energy_per_sec(rate: float, delta: float) -> void:
	if blue_energy <= 0:
		return
	var drain := int(round(rate * delta))
	if drain != 0:
		_change_energy(-drain)

func _set_boost(active: bool) -> void:
	if boost_activated == active:
		return
	boost_activated = active
	if active:
		speed *= 1.8
		angular_speed *= 1.8
	else:
		speed /= 1.8
		angular_speed /= 1.8

# ──────────────────────────────────────────────────────────────
#   DEBUG
# ──────────────────────────────────────────────────────────────
func status_report() -> void:
	print("player_id:", player_id, " pos:", global_position, " hp:", health, " energy:", blue_energy)
