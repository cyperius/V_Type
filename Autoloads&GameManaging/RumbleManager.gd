extends Node

var current_rumble_intensity: float = 0.0
var active_tween: Tween = null
var active_devices: Array[int] = [0]  # Standard: Controller 0
var array_with_controller_ids : Array[int] # Für die unten definierte rumble()-Funktion müssen die Controller ID's mit einem Array mit Int-Elementen übergeben werden


func _ready() -> void:
	
	Global.roster_changed.connect(_on_roster_changed) # Wenn Spieler intial registreiert werden oder Anzahl ändert, müssen die aktiven Controller erfasst werden
	
	
func _on_roster_changed() -> void:
	# sicher unnötig komplizierte, aber funktionierende Referenz zu aktive Controllern
	var controller_ids := Players.get_active_player_ids() # diese Funktion in Players generiert einen Array mit player_ids, welche mit 1 starten (aber keine int sind)
	
	for number in controller_ids:  # daher werden die Nummern aus dem array "controller_ids" zu int-Werten umgewandelt
		var int_number = int(number) # man könnte wohl auch einfach mit "number = int(number)" direkt umwandeln
		int_number -= 1 # die ursprünglichen player_ids begannen mit 1 -> Korrektur um -1
		array_with_controller_ids.append(int_number) # und die nun passenden Elemnte dem array "array_with_controller_ids" hinzufügen
		
	
## Startet ein explosionsartiges Rumble-Profil.
## @param duration Gesamtdauer in Sekunden.
## @param max_intensity Maximale Stärke zwischen 0.0 und 1.0.
## @param devices Array von Controller-IDs (z.B. [0,1]).
func rumble(duration: float = 1.5, max_intensity: float = 1.0, devices: Array[int] = array_with_controller_ids) -> void:
	
	active_devices = devices
	
	# Falls bereits ein Rumble läuft → sauber beenden
	if active_tween and active_tween.is_running():
		active_tween.kill()
		_stop_rumble()
	
	current_rumble_intensity = 0.0
	
	active_tween = create_tween()
	
	
	# --------------------
	# Phase 1 – Impact
	# --------------------
	# TRANS_EXPO:
	# Exponentielle Kurve.
	# Sehr starke Beschleunigung am Anfang bzw. starkes Abflachen am Ende.
	# Wirkt explosiv und aggressiv.
	active_tween.set_trans(Tween.TRANS_EXPO)
	
	# EASE_OUT:
	# Startet schnell und verlangsamt sich gegen Ende.
	# In Kombination mit EXPO ergibt das einen brutalen, sofortigen Peak.
	active_tween.set_ease(Tween.EASE_OUT)
	
	active_tween.tween_method(_update_rumble, 0.0, max_intensity, duration * 0.25)
	
	
	# --------------------
	# Phase 2 – Haupt-Abklingen
	# --------------------
	# TRANS_SINE:
	# Sinusförmige Kurve.
	# Sehr weich und natürlich wirkende Bewegung.
	# Gut geeignet für organisches Abklingen.
	active_tween.set_trans(Tween.TRANS_SINE)
	
	# EASE_IN:
	# Beginnt langsam und beschleunigt Richtung Zielwert.
	# Hier sorgt das für ein sanft einsetzendes Absinken.
	active_tween.set_ease(Tween.EASE_IN)
	
	active_tween.tween_method(_update_rumble, max_intensity, 0.25, duration * 0.5)
	
	
	# --------------------
	# Phase 3 – Subtiles Ausschleichen
	# --------------------
	# TRANS_LINEAR:
	# Lineare Interpolation ohne Beschleunigung.
	# Konstante Änderungsrate.
	# Wirkt technisch-neutral.
	active_tween.set_trans(Tween.TRANS_LINEAR)
	
	# EASE_OUT:
	# Startet schneller und flacht gegen Ende ab.
	# Lässt das Rumble gefühlt ruhig „ausrollen“.
	active_tween.set_ease(Tween.EASE_OUT)
	
	active_tween.tween_method(_update_rumble, 0.25, 0.0, duration * 1.2)
	
	
	# Wird nach Abschluss aller Tween-Schritte ausgeführt.
	# Stoppt explizit die Gamepad-Vibration.
	active_tween.tween_callback(_stop_rumble)
	

func _update_rumble(value: float) -> void:
	# Wird bei jedem Interpolationsschritt aufgerufen.
	# Standardmässig ungefähr einmal pro Render-Frame (~60x pro Sekunde).
	# Tween ist zeitbasiert, nicht framebasiert.

	current_rumble_intensity = value
	
	for device in active_devices:
		# Kurze Dauer, da wir kontinuierlich neu triggern.
		# Erster Wert = schwacher Motor
		# Zweiter Wert = starker Motor
		Input.start_joy_vibration(device, value, value, 0.05)


func _stop_rumble() -> void:
	current_rumble_intensity = 0.0
	
	for device in active_devices:
		Input.stop_joy_vibration(device)
