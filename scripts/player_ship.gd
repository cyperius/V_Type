class_name PlayerShip extends Area2D


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
var health: int							# in _ready() auf max_health gesetzt
@export var max_energy: int = 1000
var blue_energy: int					# in _ready() auf max_energy gesetzt
var score : int = 0

var shield_is_activated := false
var player_is_slowed_down := false
var controls_are_reversed := false
@export var damage: int = 10
var player_is_dead := false
var spawn_position := Vector2.ZERO

@export var shield_energy_drain : int = 100
@export var boost_energy_drain : int = 20

# ──────────────────────────────────────────────────────────────
#   WEAPONS
# ──────────────────────────────────────────────────────────────
@export var primary_weapon: PackedScene
@export var secondary_weapon: PackedScene


var projectiles := []

# ──────────────────────────────────────────────────────────────
#   GRAPHICS / FX / COLLISIONS
# ──────────────────────────────────────────────────────────────
@onready var ship_sprite: Sprite2D = %ship_sprite
@onready var player1_skin = preload("res://assets/graphic_elements/enemies/space_ship1.png")
@onready var player4_skin = preload("res://assets/graphic_elements/enemies/player2_ship.png")
@onready var player3_skin = preload("res://assets/graphic_elements/player/Luftfahrzeug.png")
@onready var player2_skin = preload("res://assets/graphic_elements/player/golden_ship.png")

@onready var just_been_hit_timer: Timer = %BeenHitTimer
@onready var hit_scene: PackedScene = preload("res://scenes/hit.tscn")
@onready var explosion_scene: PackedScene = preload("res://scenes/explosion_animation.tscn")
@onready var _particles_shield: GPUParticles2D = %ParticlesShield
@onready var _shield_collision_shape: CollisionShape2D = %ShieldCollisionShape2D2

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
	
	# Referenz im GameManger kreieren (die Variable player_ship_reference gibt es
	# dort schon mit dem Wert 'null' der nun überschrieben wird
	GameManager.reference_to_player_ship = self
	GameManager.create_player_ship_reference()

	# Stats initial setzen (Export-Werte aus dem Inspector werden respektiert)
	health = max_health
	blue_energy = max_energy

	# Skins 
	if player_id == 2:
		ship_sprite.texture = player2_skin
		ship_sprite.scale = Vector2(0.6, 0.6)
	elif player_id == 3:
		ship_sprite.texture = player3_skin
		ship_sprite.scale = Vector2(0.8, 0.9)
	elif player_id == 4:
		ship_sprite.texture = player4_skin
		ship_sprite.scale = Vector2(1, 1.4)
	else:
		ship_sprite.texture = player1_skin
		ship_sprite.scale = Vector2(0.6, 0.6)
		

	# Kollisions-Backup sichern (für Death/Revive)
	_backup_collision_layer = collision_layer
	_backup_collision_mask = collision_mask

	# Signale
	just_been_hit_timer.timeout.connect(_on_just_been_hit_timer_timeout)
	area_entered.connect(_on_area_entered)

	# Schild-Kollision initial aus
	_shield_collision_shape.disabled = true
	
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
		_emit_stats()  # UI live halten

	# Waffen  Invalid type in function 'shoot_weapon' in base 'Area2D (PlayerShip)'. The Object-derived class of argument 1 (previously freed) is not a subclass of the expected argument class.
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
			# Kurzzeitig nicht kollidieren, damit der Treffer nicht mehrfach zählt
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

func player_is_hit(damage: int) -> void:
	_change_health(-damage)
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
	collision_mask = _backup_collision_mask
	collision_layer = _backup_collision_layer

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
		print("owner id in projectil!")
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

	# kurz warten nach Zerstörung bis Game_over-Sequenz ausgelöst wird
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
