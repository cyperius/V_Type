extends Node2D

@onready var main = $".."

@export var sfx_stream: AudioStream
var explosion: PackedScene = load("res://scenes/explosion_animation.tscn")

func _ready() -> void:
	AudioManager.play_sfx(sfx_stream)
	print("ausgelöst")
	if Global.player_ship:
		# Hier greifst du auf eine Eigenschaft des Player-Schiffs zu,
		# z. B. auf einen Kind-Knoten 'ship_sprite'
		self.position = Global.player_sprite.global_position
		print("Initialposition: ", self.position)
	else:
		print("Global.player_ship ist nicht gesetzt!")
	add_child(explosion.instantiate())
	reset_level()
	
	
func reset_level():
	var timer = Timer.new()
	timer.wait_time = 3
	timer.one_shot = true
	timer.start()
	await  timer.timeout
	add_child(timer)
	main._load_level(GameManager.current_level)
		



# Invalid type in function 'get_child' in base 'Area2D (space_ship.gd)'. Cannot convert argument 1 from String to int.

#extends Node2D
#
#@export var sfx_stream: AudioStream
#var ship = null
#
#func _ready() -> void:
	#AudioManager.play_sfx(sfx_stream)
	#$AnimatedSprite2D.play()
	#print("ausgelöst")
	#if Global.player_ship:
		## Hier greifst du auf eine Eigenschaft des Player-Schiffs zu,
		## z. B. auf einen Kind-Knoten 'ship_sprite'
		#ship = Global.player_ship.get_child("ship_sprite")
		#self.position = ship.position
#
	#else:
		#print("Global.player_ship ist nicht gesetzt!")
