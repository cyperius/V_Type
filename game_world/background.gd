extends Control

var direction : int = 1
var level : Node

func _ready() -> void:
	level = get_parent()


func _physics_process(delta: float) -> void:
	if level.camera_scrolling:
		position.x += level.camera_scroll_speed * delta
