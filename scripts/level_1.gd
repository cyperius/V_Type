extends Node2D  # MainScene basiert auf Node2D

@onready var boss_timer = $BossTimer
@onready var enemy_spawner: Node2D = $EnemySpawner
@export var amount_of_enemies : int

signal level_finished(next_level_nr: int, gained_score: int, gained_energy: int)


func _ready():
	# var song1 = preload("res://assets/sound_and_sfx/soundtracks/Level_sountracks/Not Alone.wav")
	var enemy = preload("res://scenes/enemy_1.tscn").instantiate()
	enemy_spawner.connect("boss_defeated", Callable(self, "_on_boss_defeated"))
	
	
	add_child(enemy)
	#add_child(background)
	boss_timer.wait_time = 15 # kann im Editor überschrieben werden
	boss_timer.timeout.connect(_on_boss_timer_timeout)
	
	
	#background.size = Vector2(3840, 2880)  # Falls FullHD-Fenstergröße
	#background.position = Vector2(-1920, -1440)  # Stelle sicher, dass er oben links beginnt

	AudioManager.play_music("level_2")

func _on_boss_timer_timeout():
	pass
	
	
func _on_boss_defeated():
	emit_signal("level_finished", 2, 0, 0)
	print("boss defeated")
