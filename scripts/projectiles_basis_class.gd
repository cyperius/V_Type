extends Area2D

# ─── Exporte für Konfiguration im Editor oder zur Laufzeit ───────────────
@export var owner_id: int = -1                # Spieler, der das Projektil abgefeuert hat
@export var speed = 400                       # Fluggeschwindigkeit des Projektils
@export var damage = 10                       # Schaden, den das Projektil verursacht
@export var sfx_stream: AudioStream           # Optional: direkter Soundeffekt
@export var sfx_name: String = ""             # Alternativ: Soundeffektname (z. B. "laser")
@export var volume: float = 1                 # Lautstärke

# ─── Interne Variablen ───────────────────────────────────────────────────
@onready var enemy_hit_scene: PackedScene = preload("res://scenes/hit.tscn")
@onready var offset: Vector2
var shooter                                     # Referenz auf das Spieler-Schiff (vom Typ player_ship)
var angle: float                                # Richtung des Schusses (für CIRCLE-Mode)
var player_mode                                 # Schussverhalten basiert auf Modus des Spielers

# ─── Initialisierung bei Erscheinen ──────────────────────────────────────
func _ready():
	shooter = Global.get_player_ship(owner_id)

	if shooter != null:
		offset = shooter.global_position - shooter.circle_center_position
		angle = offset.angle()
		player_mode = shooter.mode

		# Optional: Projektil leicht eindrehen bei CIRCLE-Modus
		if player_mode == shooter.PlayerMode.CIRCLE:
			rotate(angle)
			start_tweens()

	else:
		print("⚠️ Kein Spieler mit ID %d gefunden!" % owner_id)

	# Signale, Gruppen und Verarbeitung vorbereiten
	area_entered.connect(_on_area_entered)
	add_to_group("projectiles")
	set_process(true)

# ─── Bewegung / Verhalten ────────────────────────────────────────────────
func _process(delta):
	if shooter == null:
		return  # Sicherheitshalber stoppen, wenn kein gültiger Spieler

	match player_mode:
		shooter.PlayerMode.FREE:
			_process_horizontal(delta)
		shooter.PlayerMode.CIRCLE:
			_process_circle(delta)

func _process_horizontal(delta):
	position.x += speed * delta

	# Entferne Projektil, wenn es den Bildschirm verlässt
	if position.x > 4000:
		queue_free()

func _process_circle(delta):
	# Verwendet die Tween-Skalierung, um das Projektil nach Zeit verschwinden zu lassen
	if scale < Vector2(0.1, 0.1):
		queue_free()

# ─── Treffererkennung (auf Area2D-Objekte) ───────────────────────────────
func _on_area_entered(area: Area2D):
	if not area.is_in_group("one_hit_enemies"):
		var enemy_hit = enemy_hit_scene.instantiate()
		get_tree().current_scene.add_child(enemy_hit)
		enemy_hit.position = global_position

	if area.is_in_group("asteroids"):
		queue_free()
	else:
		queue_free()

# ─── Bewegungseffekte für CIRCLE-Mode ────────────────────────────────────
func start_tweens():
	var center_tween = create_tween()
	center_tween.tween_property(
		self,
		"position",
		shooter.circle_center_position,
		5000 / (speed * 3)
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	var shrink_tween = create_tween()
	shrink_tween.tween_property(
		self,
		"scale",
		Vector2(0.05, 0.05),
		5000 / (speed * 3)
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

# ─── Soundeffekt beim Abfeuern (kann z. B. aus player_ship aufgerufen werden) ──
func fire():
	if sfx_stream:
		AudioManager.play_sfx(sfx_stream, volume)
	elif sfx_name != "":
		AudioManager.play_sfx_string(sfx_name, volume)
