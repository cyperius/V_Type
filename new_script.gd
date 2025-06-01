# Die Klasse erbt von Area2D, was Kollisionserkennung ermöglicht
extends Area2D

# Aktuelle Bewegungsrichtung und -geschwindigkeit (x und y Komponenten)
var velocity := Vector2(240, 240)

# @export macht diese Variablen im Godot Editor sichtbar und einstellbar
# PackedScene ist ein Typ für vorbereitete Szenen (wie unsere Laser-Projektile)
@export var laser_beam: PackedScene    # Szene für den normalen Laser
@export var laser_blast: PackedScene   # Szene für den starken Laser
# Grundgeschwindigkeit des Raumschiffs (Pixel pro Sekunde)
@export var max_speed = 600
var speed = max_speed
@export var max_health : int = 400
var health = max_health
@export var game_over_jingle : AudioStream # AudioStream ist anscheinend ein Datentyp
@export var damage : int = 10
@export var game_over : PackedScene # Game Over Szene
@onready var just_been_hit_timer = $Timer
# Diese Variablen speichern die aktiven Waffen
var primary_weapon: PackedScene        # Hauptwaffe
var secondary_weapon: PackedScene      # Sekundärwaffe
var projectiles = []                   # Liste aller aktiven Projektile
# health_ratio bestimmen um für Farbgebung und allenfalls weitere Effekte zu verwenden
var health_ratio 

# Diese Funktion wird beim Start der Szene automatisch ausgeführt
func _ready():
	# Sobald das Spieler-Schiff instanziiert und bereit ist, setzen wir den globalen Verweis darauf.
	# Damit können andere Scripts jederzeit über Global.player_ship darauf zugreifen.
	Global.player_ship = self

	# Wir setzen zusätzlich eine Referenz auf den Sprite des Schiffs (z. B. für Farbänderungen oder Animationen)
	Global.player_sprite = self.get_node("ship_sprite")  # Node-Name muss genau stimmen!

	# Debug: Falls du die Zeile brauchst, um zu prüfen, ob das Sprite gefunden wurde:
	# print("Ship Sprite vorhanden:", has_node("ship_sprite"))

	# Timer-Signal verbinden – z. B. um nach einem Treffer kurz unverwundbar zu sein oder zu blinken
	just_been_hit_timer.timeout.connect(_on_just_been_hit_timer_timeout)

	# Debug-Ausgabe: aktueller Health-Wert (wenn health vorher korrekt initialisiert ist)
	print(health)

	# Weist den Waffen-Variablen die entsprechenden Szenen zu
	primary_weapon = laser_beam
	secondary_weapon = laser_blast
	area_entered.connect(_on_area_entered)
	

func _on_area_entered(area_that_entered)-> void:
	
	print("Ich bin getroffen")
	collision_mask = 0
	if health <= 0:
		print("I'm already dead!")
		return
	else:
		var damage_inflicted = area_that_entered.damage
		player_is_hit(damage_inflicted)


func player_is_hit(damage):
	print("health: ", health)
	health -= damage
	print("damage: ",damage, "ergo new health: ", health)
	health_ratio = health / max_health 
	modulate = Color(1, health_ratio, health_ratio)
	# print("ich nehme Schaden")
	if health <= 0:
		var game_over_now = game_over.instantiate()
		var current_scene = get_tree().current_scene
		if current_scene:
			current_scene.add_child(game_over_now)
		hide()
	just_been_hit_timer.start()

func _on_just_been_hit_timer_timeout() -> void:
	collision_mask = (1 << 2) | (1 << 3) | (1 << 4) | (1 << 5)
	# ("um die Ebenen 3, 4, 5 und 6 in deiner Collision-Maske wieder zu aktivieren, kannst du die Bit-Shift-Notation verwenden.")


# Diese Funktion wird jeden Frame ausgeführt
# delta ist die Zeit seit dem letzten Frame in Sekunden
func _process(delta: float) -> void:

	var all_projectiles = get_tree().get_nodes_in_group("projectiles")
	#print("Aktuelle Projektile in Szene:", all_projectiles.size())

	# Bewegungssteuerung des Schiffs
	var direction := Vector2(0, 0)  # Startet mit Nullvektor (keine Bewegung)
	#print("ship_position:", position)
	# Ermittelt die Bewegungsrichtung basierend auf den Eingaben
	# get_axis gibt Werte zwischen -1 und 1 zurück
	direction.x = Input.get_axis("backward", "forward")  # Links/Rechts
	direction.y = Input.get_axis("up", "down")          # Hoch/Runter
	
	# Grösse des Fensters erfassen (zwecks Bewegungsbegrenzung)
	var screensize = get_viewport_rect().size
	
	# Berechnet die aktuelle Geschwindigkeit
	velocity = direction * speed
	# Aktualisiert die Position des Schiffs
	position += velocity * delta
	position.x = clampf(position.x, 0, screensize.x)
	position.y = clampf(position.y, 0, screensize.y)

	# Beschleunigung: Erhöht die Geschwindigkeit um 50%
	if Input.is_action_just_pressed("accelarate"):
		speed *= 1.5
	
	# Wenn Beschleunigung losgelassen wird, zurück zur normalen Geschwindigkeit
	if Input.is_action_just_released("accelarate"):
		speed /= 1.5
	
	# Bremsen: Reduziert die Geschwindigkeit um 50%    
	if Input.is_action_just_pressed("brake"):
		speed *= 0.5
	# Wenn Bremse losgelassen wird, zurück zur normalen Geschwindigkeit
	if Input.is_action_just_released("brake"):
		speed *= 2

	# Überprüft Waffeneingaben und löst entsprechende Waffen aus
	if Input.is_action_just_pressed("primary_weapon"):
		#print("Schusstaste gedrückt!")
		#print("Primary Weapon:", primary_weapon)  # Teste, ob eine Szene zugewiesen ist
		shoot_weapon(primary_weapon)
	
	if Input.is_action_just_pressed("secondary_weapon"):
		shoot_weapon(secondary_weapon)
		# print("Schusstaste gedrückt!") 
	

# Funktion zum Abfeuern einer Waffe
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
