# res://scripts/camera_utils.gd
extends Node
class_name CameraUtils
# class_name macht die Klasse global bekannt (falls du sie ohne Autoload nutzen willst)

# Gibt das aktuell sichtbare Welt-Rechteck des Viewports zurück (Weltkoordinaten)
static func get_visible_world_rect(viewport: Viewport) -> Rect2:
	# Sichtbarer Pixelbereich im Viewport (berücksichtigt z.B. Letterboxing)
	var viewport_size_pixels: Vector2 = viewport.get_visible_rect().size
	
	# Inverse Canvas-Transformation: Screen -> Welt
	var inverse_canvas: Transform2D = viewport.get_canvas_transform().affine_inverse()
	
	# Screen-Ecken in Weltkoordinaten umrechnen
	var top_left_world: Vector2 = inverse_canvas * Vector2(0.0, 0.0)
	var bottom_right_world: Vector2 = inverse_canvas * viewport_size_pixels
	
	# Rect2 in Weltkoordinaten zurückgeben
	return Rect2(top_left_world, bottom_right_world - top_left_world)


# Verwendet den return value von get_visible_world_rect() (oben definiert)
# -> das ist ein Rect2, ein Rect2 hat die in-built-Methode get.center()
static func get_center_world_coordinates(viewport: Viewport) -> Vector2:
	return get_visible_world_rect(viewport).get_center()
	
