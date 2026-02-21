# ============================================================
# Script: enemy_spawner.gd
# Zweck:
#	Spawnt Gegner ausserhalb des aktuell sichtbaren Bildschirm-
#	bereichs, relativ zur aktiven Camera2D.
#	Der Spawn-Abstand ist optisch konstant (Pixel-basiert),
#	auch bei dynamischem Camera-Zoom.
# ============================================================

extends Node2D
# Node2D, damit der Spawner selbst eine Weltposition haben kann
# (auch wenn wir für Spawns global_position verwenden)

# ------------------------------------------------------------
# Export-Variablen (im Inspector pro Level einstellbar)
# ------------------------------------------------------------

@export var spawn_margin_pixels: float = 200.0
# Abstand zum sichtbaren Bildrand in SCREEN-PIXELN
# (z.B. 200 px rechts ausserhalb des Bildes)

@export var spawn_random_extra_pixels: float = 150.0
# Zusätzlicher Zufallsbereich ausserhalb der Bildschirmhöhe
# (z.B. etwas über/unter dem sichtbaren Bereich)

# ------------------------------------------------------------
# Referenz auf die aktive Kamera
# ------------------------------------------------------------

@onready var camera: Camera2D = %Camera2D
# Holt sich die Camera2D mit "Unique Name" aus der main_scene
# %Camera2D ist robust gegenüber Refactoring im Scene-Tree

# ------------------------------------------------------------
# Hilfsfunktion:
# Screen-Pixel → Weltkoordinaten umrechnen
# ------------------------------------------------------------

func pixels_to_world(pixels: float) -> float:
	# Wandelt eine Pixel-Distanz (Screen Space)
	# in eine Welt-Distanz um, abhängig vom aktuellen Zoom
	return pixels / camera.zoom.x
	# Bei zoom.x > 1.0 (reingezoomt) wird die Welt-Distanz kleiner
	# Bei zoom.x < 1.0 (rausgezoomt) wird sie grösser
	# → optisch konstanter Abstand

# ------------------------------------------------------------
# Schritt 1:
# Sichtbaren Welt-Ausschnitt der Kamera berechnen
# ------------------------------------------------------------

func get_visible_world_rect() -> Rect2:
	# Grösse des Viewports in PIXELN (-> .size), auf den die Kamera rendert
	# und der sichtbar ist ( ->get_visible_rect() )
	var viewport_size_pixels: Vector2 = camera.get_viewport().get_visible_rect().size
	
	# Umrechnung von Pixeln in Weltkoordinaten (unter Berücksichtigung des Zooms)
	var visible_world_size: Vector2 = viewport_size_pixels / camera.zoom
	
	# Berechnung der oberen linken Ecke des sichtbaren Weltbereichs
	# Camera2D ist standardmässig im Zentrum des Bildes
	var top_left: Vector2 = camera.global_position - (visible_world_size * 0.5)
	
	# Rückgabe des sichtbaren Welt-Rechtecks
	return Rect2(top_left, visible_world_size)

# ------------------------------------------------------------
# Schritt 2–4:
# Spawn-Position RECHTS ausserhalb des sichtbaren Bereichs
# (optisch konstanter Abstand)
# ------------------------------------------------------------

func get_spawn_position_outside_right() -> Vector2:
	# Sichtbaren Weltbereich holen
	var rect: Rect2 = get_visible_world_rect()
	
	# Spawn-Abstand vom Bildschirmrand (Pixel → Welt)
	var margin_world: float = pixels_to_world(spawn_margin_pixels)
	
	# Zufallsbereich ober-/unterhalb des sichtbaren Bereichs
	var random_extra_world: float = pixels_to_world(spawn_random_extra_pixels)
	
	# X-Position: rechts ausserhalb des sichtbaren Bereichs
	var x: float = rect.position.x + rect.size.x + margin_world
	
	# Y-Bereich: leicht über und unter dem sichtbaren Bereich
	var y_min: float = rect.position.y - random_extra_world
	var y_max: float = rect.position.y + rect.size.y + random_extra_world
	
	# Zufällige Y-Position innerhalb dieses Bereichs
	return Vector2(x, randf_range(y_min, y_max))

# ------------------------------------------------------------
# Schritt 5:
# Gegner instanziieren und korrekt platzieren
# ------------------------------------------------------------

func spawn_enemy(enemy_scene: PackedScene) -> void:
	# Neue Gegner-Instanz aus der Scene erzeugen
	var enemy := enemy_scene.instantiate()
	
	# Gegner in den Scene-Tree einhängen
	add_child(enemy)
	
	# Gegner an der berechneten Weltposition platzieren
	enemy.global_position = get_spawn_position_outside_right()
