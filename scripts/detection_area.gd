class_name DetectionZone extends Area2D
signal player_detected

func _ready() -> void:
	area_entered.connect(_on_arae_entered)
	var parent = get_parent()
	if parent.has_method("_on_player_detected"):
		player_detected.connect(parent._on_player_detected)
	
	
func _on_arae_entered(other: Area2D) -> void:
	if other.is_in_group("players"):
		player_detected.emit()
