extends Area2D

# ─── Exporte für Konfiguration im Editor oder zur Laufzeit ───────────────
@export var owner_id: int = -1				# Spieler-ID, der das Projektil abgefeuert hat, beim Feuern
											# wird von player_ship.gd her die richtigen ID überschrieben
@export var speed: float = 400.0			# Fluggeschwindigkeit
@export var damage: int = 10				# Schaden des Projektils
@export var sfx_stream: AudioStream			# Optional: direkter Soundeffekt
@export var sfx_name: String = ""			# Alternativ: Soundeffektname (z. B. "laser")
@export var volume: float = 1.0				# Lautstärke

# ─── Interne Variablen ───────────────────────────────────────────────────
@onready var enemy_hit_scene: PackedScene = preload("res://game_world/hit.tscn")

var velocity: Vector2 = Vector2.ZERO
var circle_center_position: Vector2 = Vector2.ZERO
var circle_mode_enabled: bool = false

# ─── Initialisierung bei Erscheinen ──────────────────────────────────────
func _ready() -> void:
	# Shooter einmalig „snapshotten“ (robust, falls der Spieler den Tree verlässt)
	var shooter: PlayerShip = Global.get_player_ship(owner_id) as PlayerShip
	if shooter != null:
		circle_mode_enabled = (shooter.mode == shooter.PlayerMode.CIRCLE) # circle_mode_enabled wird auf "true" gesetzt, falls der PlayerMode entsprechnd gesetzt ist (was wiederum im jew. Level vorgenoommen wird)
		if circle_mode_enabled:
			# Richtung aus Spieler-Position relativ zum Kreiszentrum ableiten
			var offset: Vector2 = shooter.global_position - shooter.circle_center_position
			var angle: float = offset.angle()
			rotation = angle
			circle_center_position = shooter.circle_center_position
			start_tweens(angle)
		else:
			# Linearer Schuss nach rechts (bei Bedarf später an Mündung/Rotation koppeln)
			velocity = Vector2.RIGHT * speed
	else:
		# Fallback: linear nach rechts
		velocity = Vector2.RIGHT * speed

	area_entered.connect(_on_area_entered)
	add_to_group("projectiles")
	set_physics_process(true)

# ─── Bewegung / Verhalten ────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	if circle_mode_enabled:
		# Circle-Variante wird per Tween bewegt; hier nichts tun
		return

	position += velocity * delta

	# Off-screen entsorgen (mit kleinem Rand)
	var rect := get_viewport_rect().grow(64)
	if not rect.has_point(global_position):
		queue_free()

# ─── Treffererkennung (auf Area2D-Objekte) ───────────────────────────────
func _on_area_entered(area: Area2D) -> void:
	# Friendly Fire verhindern: eigenes Schiff ignorieren
	if area is PlayerShip:
		return

	# Treffer-VFX (nicht für Asteroiden, falls du dort keinen Effekt willst)
	if not area.is_in_group("asteroids"):
		var enemy_hit = enemy_hit_scene.instantiate()
		get_tree().current_scene.add_child(enemy_hit)
		enemy_hit.global_position = global_position
		
	

	# Schaden anwenden, wenn das Ziel eine passende API anbietet
	if "player_is_hit" in area:
		area.player_is_hit(int(damage))
	elif "apply_damage" in area:
		area.apply_damage(damage, owner_id) # Invalid call to function 'apply_damage' in base 'Area2D (enemy)'. Expected 2 arguments.
		# apply score existiert im Moment noch nicht 
		# Idee: der owner des Schusses und die zu addierende Score
		# muss weiter gegeben werden (als "Platzhalter_Mechanik" hier mal 
		# damge = score angenommen
		#area.apply_score(int(damage), int(owner_id))
	# Ansonsten ist das Ziel „passiv“ → nur Effekte ohne Schaden

	# Projektil nach dem Treffer entfernen
	queue_free()

# ─── Bewegungseffekte für CIRCLE-Mode ────────────────────────────────────
func start_tweens(angle: float) -> void:
	var duration := 5000.0 / (speed * 3.0)

	var center_tween := create_tween()
	center_tween.tween_property(
		self,
		"position",
		circle_center_position,
		duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	var shrink_tween := create_tween()
	shrink_tween.tween_property(
		self,
		"scale",
		Vector2(0.05, 0.05),
		duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Auto-Despawn am Ende der Schrumpfanimation
	shrink_tween.finished.connect(func() -> void:
		queue_free())

# ─── Soundeffekt beim Abfeuern (kann z. B. aus player_ship aufgerufen werden) ──
func fire() -> void:
	if sfx_stream:
		AudioManager.play_sfx(sfx_stream, volume)
	elif sfx_name != "":
		AudioManager.play_sfx_string(sfx_name, volume)
