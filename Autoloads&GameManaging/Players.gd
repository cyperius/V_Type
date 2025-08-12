extends Node
class_name PlayersManager  # <— NICHT "Players", sonst Konflikt mit Autoload-Namen


# ──────────────────────────────────────────────────────────────
#   SIGNALS
# ──────────────────────────────────────────────────────────────
signal player_joined(player_id: int, device_id: int)
signal player_left(player_id: int, device_id: int)
signal mapping_changed()

# ──────────────────────────────────────────────────────────────
#   SETTINGS
# ──────────────────────────────────────────────────────────────
const MAX_PLAYERS := 4

# ──────────────────────────────────────────────────────────────
#   STATE
# ──────────────────────────────────────────────────────────────
var device_to_player: Dictionary = {} # device_id -> player_id
var player_to_device: Dictionary = {} # player_id -> device_id

# ──────────────────────────────────────────────────────────────
#   JOIN / LEAVE
# ──────────────────────────────────────────────────────────────
func join(device_id: int) -> int:
	# Falls Gerät schon drin → ID zurückgeben
	if device_to_player.has(device_id):
		return device_to_player[device_id]

	var free_id := _next_free_player_id()
	if free_id == -1:
		print("No free player slots available!")
		return -1

	device_to_player[device_id] = free_id
	player_to_device[free_id] = device_id

	player_joined.emit(free_id, device_id)
	mapping_changed.emit()
	print("Player joined: ID =", free_id, " Device =", device_id)
	return free_id

func leave_by_player(player_id: int) -> void:
	if not player_to_device.has(player_id):
		return
	var dev: int = player_to_device[player_id]
	player_to_device.erase(player_id)
	device_to_player.erase(dev)

	player_left.emit(player_id, dev)
	mapping_changed.emit()
	print("Player left: ID =", player_id, " Device =", dev)

func leave_by_device(device_id: int) -> void:
	if not device_to_player.has(device_id):
		return
	var pid: int = device_to_player[device_id]
	leave_by_player(pid)

# ──────────────────────────────────────────────────────────────
#   HELPERS
# ──────────────────────────────────────────────────────────────
func get_active_player_ids() -> Array:
	var ids := player_to_device.keys()
	ids.sort()
	return ids

func get_device_for_player(player_id: int) -> int:
	return player_to_device.get(player_id, -1)

func get_player_for_device(device_id: int) -> int:
	return device_to_player.get(device_id, -1)

func get_active_count() -> int:
	return player_to_device.size()

func is_full() -> bool:
	return get_active_count() >= MAX_PLAYERS

func reset_all() -> void:
	device_to_player.clear()
	player_to_device.clear()
	mapping_changed.emit()

# ──────────────────────────────────────────────────────────────
#   INTERNAL
# ──────────────────────────────────────────────────────────────
func _next_free_player_id() -> int:
	for id in range(1, MAX_PLAYERS + 1):
		if not player_to_device.has(id):
			return id
	return -1
