extends Control

# Holt sich das Label erst, wenn die Szene vollständig geladen ist
@onready var center_label: Label = $CenterLabel

func _ready():
	# Initialisiere Zufallszahlen für die Schriftgrössen-Variante
	randomize()

	# call_deferred sorgt dafür, dass update_label_position erst aufgerufen wird,
	# wenn alle Nodes und ihre onready-Variablen garantiert initialisiert sind
	call_deferred("update_label_position")

	print("💡 center_label ist:", center_label)

func _notification(what):
	# Diese Methode wird automatisch bei Systemereignissen aufgerufen (z.B. Fenstergösse geändert)
	# Wir stellen sicher, dass center_label existiert, bevor wir darauf zugreifen
	if what == NOTIFICATION_RESIZED and center_label:
		print("✅ Fenstergrösse geändert!")
		update_label_position()

		# Zufällige Schriftgrösse zwischen 20 und 39
		center_label.add_theme_font_size_override("font_size", 20 + randi() % 20)

func update_label_position():
	# Bildschirmgrösse über size (Control-spezifisch)
	var screen_size = size
	print("📏 Bildschirmgrösse:", screen_size)
	print("🪟 Fenstergrösse (real):", get_window().size)
	print("🖼️ Scene-Grösse (size):", size)


	# Optional: Explizit die Grösse des Labels setzen, falls sie noch nicht korrekt berechnet wurde
	center_label.size = center_label.get_minimum_size()
	print("🧾 Label-Grösse:", center_label.size)

	# Zentriere das Label: Position = Bildschirmmitte, verschoben um halbe Label-Grösse
	center_label.pivot_offset = center_label.size / 2.0
	center_label.position = screen_size / 2.0
