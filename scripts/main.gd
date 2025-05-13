extends Node2D  # MainScene basiert auf Node2D

func _ready():
	# var song1 = preload("res://assets/sound_and_sfx/soundtracks/Level_sountracks/Not Alone.wav")
	var boss = preload("res://scenes/boss_1.tscn").instantiate()
	var enemy = preload("res://scenes/enemy_1.tscn").instantiate()
	#var enemy_spawner = preload("res://scenes/enemy_spawner.tscn").instantiate()
	
	add_child(enemy)
	#add_child(background)
	add_child(boss)
	boss.global_position = Vector2(2800, 1100)

	
	#background.size = Vector2(3840, 2880)  # Falls FullHD-Fenstergröße
	#background.position = Vector2(-1920, -1440)  # Stelle sicher, dass er oben links beginnt

	#AudioManager.play_music("level_2")

