extends Area2D
@onready var left_wing_anchor: Marker2D = %LeftWingAnchor
@onready var left_wing: Sprite2D = %LeftWing
@onready var right_wing_anchor: Marker2D = %RightWingAnchor
@onready var right_wing: Sprite2D = %RightWing
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
var outer_left_angle_reached = false
var outer_right_angle_reached = false


func _process(delta: float) -> void:
	if outer_left_angle_reached == false:
		left_wing_anchor.rotation_degrees -= 8
		if left_wing_anchor.rotation_degrees <= -16:
			outer_left_angle_reached = true
	if outer_left_angle_reached == true:
		left_wing_anchor.rotation_degrees += 8
		if left_wing_anchor.rotation_degrees >= 16:
			outer_left_angle_reached = false

	if outer_right_angle_reached == false:
		right_wing_anchor.rotation_degrees += 8
		if right_wing_anchor.rotation_degrees >= 16:
			outer_right_angle_reached = true
	if outer_right_angle_reached == true:
		right_wing_anchor.rotation_degrees -= 8
		if right_wing_anchor.rotation_degrees <= -16:
			outer_right_angle_reached = false
