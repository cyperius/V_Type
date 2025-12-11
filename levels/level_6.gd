extends LevelBase

#signal just_touched_left_boarder
#signal just_touched_right_boarder


@onready var last_touched_right_boarder := false
@onready var last_touched_left_boarder := true
@onready var left_boarder: Area2D = %left_boarder
@onready var right_boarder: Area2D = %right_boarder
#
#func _ready() -> void:
	
	#left_boarder.area_entered.connect(_on_left_boarder_entered)
	#right_boarder.area_entered.connect(_on_right_boarder_entered)
	

#
#func _on_left_boarder_entered() -> void:
	#emit_signal("just_touched_left_boarder")
	#last_touched_left_boarder = true
	#last_touched_right_boarder = false
	#
	#
#func _on_right_boarder_entered() -> void:
	#last_touched_right_boarder = true
	#last_touched_left_boarder = false
	

	
