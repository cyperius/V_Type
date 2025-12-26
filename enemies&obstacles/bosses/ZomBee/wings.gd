extends Area2D
signal wings_hit

@onready var left_wing_anchor: Marker2D = %LeftWingAnchor
@onready var left_wing: Sprite2D = %LeftWing
@onready var right_wing_anchor: Marker2D = %RightWingAnchor
@onready var right_wing: Sprite2D = %RightWing
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
var outer_left_angle_reached = false
var outer_right_angle_reached = false
@onready var wings: Area2D = %Wings


func _ready() -> void:
	#area_entered.connect(_on_area_entered)
	pass

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
		if right_wing_anchor.rotation_degrees <= -32:
			outer_right_angle_reached = false
			
#func _on_area_entered(area_that_entered):
	#if area_that_entered.is_in_group("projectiles"):
		#set_process(false)
		#emit_signal("wings_hit")
	#
