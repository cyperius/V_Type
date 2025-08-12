extends Node

# ──────────────────────────────────────────────────────────────
#   SIGNALS (Main hängt sich hier dran)
# ──────────────────────────────────────────────────────────────
signal player_joined(player_id: int)
signal player_left(player_id: int)

# ──────────────────────────────────────────────────────────────
#   LEBENSZYKLUS
# ──────────────────────────────────────────────────────────────
func _ready() -> void:
	# Wenn dieses Skript als Node in Main hängt, lauschen wir auf Änderungen an Gamepads:
	# - Wird ein Pad verbunden/entfernt, kriegen wir ein Event.
	Input.joy_connection_changed.connect(_on_device_changed)

	# Falls bereits Geräte verbunden sind (z. B. Pad war vor Start an), holen wir sie nach:
	for device_id in Input.get_connected_joypads():
		_on_device_connected(device_id)

# ──────────────────────────────────────────────────────────────
#   GERÄTE-HANDLING
# ──────────────────────────────────────────────────────────────
func _on_device_changed(device_id: int, connected: bool) -> void:
	if connected:
		_on_device_connected(device_id)
	else:
		_on_device_disconnected(device_id)

func _on_device_connected(device_id: int) -> void:
	# Weist über Players.gd (Autoload) dem Device eine freie player_id zu.
	# join() gibt die vergebene ID zurück oder -1 wenn voll/duplikat.
	var new_player_id: int = Players.join(device_id)
	if new_player_id != -1:
		player_joined.emit(new_player_id)
		print("✅ Device", device_id, "joined as Player", new_player_id)
	else:
		print("❌ Device", device_id, "could not join (full or duplicate)")

func _on_device_disconnected(device_id: int) -> void:
	# Holt zu diesem Device die player_id und trägt sie aus.
	var player_id: int = Players.get_player_for_device(device_id)
	if player_id != -1:
		Players.leave_by_device(device_id)
		player_left.emit(player_id)
		print("🚪 Device", device_id, "disconnected from Player", player_id)

# ──────────────────────────────────────────────────────────────
#   ABFRAGEN (für Main, falls nötig)
# ──────────────────────────────────────────────────────────────
func get_active_player_ids() -> Array:
	# Reicht die Liste der aktiven Player‑IDs aus Players.gd durch.
	return Players.get_active_player_ids()

# ──────────────────────────────────────────────────────────────
#   OPTIONALE KEYBOARD-JOIN/LEAVE (lokal)
# ──────────────────────────────────────────────────────────────
func join_keyboard() -> void:
	var player_id: int = Players.join(0) # 0 = Tastatur als „Gerät“
	if player_id != -1:
		player_joined.emit(player_id)
		print("⌨ Keyboard joined as Player", player_id)

func leave_keyboard() -> void:
	var player_id: int = Players.get_player_for_device(0)
	if player_id != -1:
		Players.leave_by_player(player_id)
		player_left.emit(player_id)
		print("⌨ Keyboard left Player", player_id)
