class_name ExplosionAnimation
extends AnimatedSprite2D


@onready var audio_stream_player_2d = $AudioStreamPlayer2D
@export var rumble_intensity : float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animation_finished.connect(_on_animation_finished)
	play()
	audio_stream_player_2d.play()


var current_rumble_intensity: float = 0.0

## Startet ein ansteigendes Gamepad-Rumble.
## @param duration Dauer der Interpolation in Sekunden.
## @param max_intensity Zielstärke zwischen 0.0 und 1.0.
func rumble(duration: float = 1.5, max_intensity: float = 1.0) -> void:
	current_rumble_intensity = 0.0
	
	var tween = create_tween()
	
	# --------------------
	# Phase 1 – Impact
	# --------------------
	# TRANS_EXPO:
	# Exponentielle Kurve.
	# Sehr starke Beschleunigung am Anfang bzw. sehr starkes Abflachen am Ende.
	# Wirkt explosiv und aggressiv.
	tween.set_trans(Tween.TRANS_EXPO)
	
	# EASE_OUT:
	# Startet schnell und verlangsamt sich gegen Ende.
	# In Kombination mit EXPO ergibt das einen brutalen, sofortigen Peak.
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_method(_update_rumble, 0.0, max_intensity, duration * 0.25)
	
	
	# --------------------
	# Phase 2 – Haupt-Abklingen
	# --------------------
	# TRANS_SINE:
	# Sinusförmige Kurve.
	# Sehr weich und natürlich wirkende Bewegung.
	# Gut geeignet für organisches Abklingen.
	tween.set_trans(Tween.TRANS_SINE)
	
	# EASE_IN:
	# Beginnt langsam und beschleunigt Richtung Zielwert.
	# Hier sorgt das für ein sanft einsetzendes Absinken.
	tween.set_ease(Tween.EASE_IN)
	
	tween.tween_method(_update_rumble, max_intensity, 0.25, duration * 0.5)
	
	
	# --------------------
	# Phase 3 – Subtiles Ausschleichen
	# --------------------
	# TRANS_LINEAR:
	# Lineare Interpolation ohne Beschleunigung.
	# Konstante Änderungsrate.
	# Wirkt technisch-neutral.
	tween.set_trans(Tween.TRANS_LINEAR)
	
	# EASE_OUT:
	# Startet schneller und flacht gegen Ende ab.
	# Lässt das Rumble gefühlt ruhig „ausrollen“.
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_method(_update_rumble, 0.25, 0.0, duration * 1.2)
	
	
	# Wird nach Abschluss aller Tween-Schritte ausgeführt.
	# Stoppt explizit die Gamepad-Vibration.
	tween.tween_callback(_stop_rumble)


func _update_rumble(value: float) -> void:
	# Wird bei jedem Interpolationsschritt aufgerufen.
	# Standardmässig läuft create_tween() im Idle-Prozess,
	# also ungefähr einmal pro Render-Frame (~60x pro Sekunde bei 60 FPS).
	# Tween ist zeitbasiert – bei FPS-Drops bleibt die Dauer korrekt.

	current_rumble_intensity = value
	
	# Startet eine kurze Vibration mit der aktuellen Stärke.
	# Da diese Funktion während des Tweens mehrfach pro Sekunde aufgerufen wird,
	# wird die Vibrationsstärke kontinuierlich aktualisiert.
	# Die kurze Dauer (z.B. 0.05–0.1s) sorgt dafür, dass die Vibration
	# regelmässig überschrieben und angepasst wird.
	Input.start_joy_vibration(0, value, value, 0.05)

func _stop_rumble() -> void:
	# Wird nach Abschluss der Interpolation einmalig aufgerufen.
	# Stoppt explizit die Hardware-Vibration.
	Input.stop_joy_vibration(0)


func _on_animation_finished() -> void:
	queue_free()
	
	
