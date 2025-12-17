extends enemy

signal just_touched_boarder

@export var breakout_speed: int = 500

var breakout_path_follow: PathFollow2D = null
var hive_brain: Node = null
var just_changed_direction: bool = false
var attack_mode: bool = false

@onready var behaviour_timer: Timer = $BehaviourTimer


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	add_to_group("enemies")

	add_child(shoot_timer)
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	shoot_timer.start()

	audio_stream_player_2d.stream = shot_sound

	hive_brain = get_parent()
	if hive_brain and hive_brain.has_signal("change_direction"):
		hive_brain.change_direction.connect(_on_change_direction)

	# Signale verbinden
	just_touched_boarder.connect(hive_brain._on_just_touched_boarder)
	behaviour_timer.timeout.connect(_on_behaviour_change)
	

func _process(delta: float) -> void:
	if not attack_mode:
		position.x += delta * speed * direction.x
		if position.y > 2000:
			queue_free()
		return

	# --- Attack / Breakout Mode ---
	if breakout_path_follow == null or not is_instance_valid(breakout_path_follow):
		attack_mode = false
		push_warning("attack_mode war true, aber breakout_path_follow ist null/ungueltig.")
		return

	breakout_path_follow.progress += breakout_speed * delta
	global_position = breakout_path_follow.global_position
	# rotation = breakout_path_follow.rotation # 17.12.2025 aktuell ungenutzt / funktioniert schlecht
	# aber bei Bedarf damit experimentieren

# Diese Funktion wird durch folgende Funktion den Enemy_spawner im Level ausgelöst: 
# func _assign_unique_breakout_follow(invader: Node, path_2d: Path2D) -> void:
# dort gescheiht (gekürzt):
# 1) var follow: PathFollow2D = PathFollow2D.new() -> 
# 2) path_2d.add_child(follow) -> path_2d ist ein Node im SceneTree des Enemy_spawner und kriegt hier das child (follow)
# 3) invader.set_breakout_path_follow(follow)
func set_breakout_path_follow(path_follow: PathFollow2D) -> void:
	breakout_path_follow = path_follow


func _exit_tree() -> void:
	# Follow aufraeumen, damit nicht unsichtbare Follows im Path2D liegen bleiben
	if breakout_path_follow != null and is_instance_valid(breakout_path_follow):
		breakout_path_follow.queue_free()
	breakout_path_follow = null


func _on_area_entered(other: Area2D) -> void:
	emit_signal("just_touched_boarder")

	#if "damage" and "owner_id" in other: 
		#apply_damage(other.damage, other.owner_id)


func _on_change_direction() -> void:
	# Ausbrecher sollen NICHT mehr von der Formation umgedreht werden
	if attack_mode:
		return

	if just_changed_direction:
		return

	just_changed_direction = true
	var tween = create_tween()
	tween.tween_property(self, "position:y", global_position.y + 100, 0.2)

	direction *= -1

	await get_tree().create_timer(0.5).timeout
	just_changed_direction = false


func _on_behaviour_change() -> void:
	if attack_mode: # wenn der invader schon im attach mode ist, abbrechen
		return

	if randi_range(1, 24) != 1: # Wahrscheinlohckeit, dass attack mode ausgelöst wird
		return

	if breakout_path_follow == null or not is_instance_valid(breakout_path_follow):
		push_warning("Breakout versucht, aber breakout_path_follow ist nicht gesetzt.")
		return
	
	
	var path_2d := breakout_path_follow.get_parent() as Path2D  # parent wird gefunden! Ablauf: 
	# 1) in diesem Script wird oben die globale Variable mit "var breakout_path_follow: PathFollow2D = null" gesetzt
	# 2) die oben definierte "func set_breakout_path_follow()" wird durch den Enemy_Spawner ausgelöst
	# 3) im Enemy_Spawner wird wiederum ein Follow2D kreiert und dieser als child dem "Path2D" im Level zugeordnet
	# 4) "breakout_path_follow" kriegt nur durch die Funktion -> 2) eine Referenz auf eben diesen -> 3) Follow 2D mit dem Path2d als parent
	if path_2d == null or path_2d.curve == null:
		push_warning("Breakout: Path2D oder Curve fehlt.")
		return

	var local_point := path_2d.to_local(global_position)
	var closest_offset := path_2d.curve.get_closest_offset(local_point)
	breakout_path_follow.progress = closest_offset

	attack_mode = true
