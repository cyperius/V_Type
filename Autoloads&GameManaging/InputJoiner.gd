extends Node

# ──────────────────────────────────────────────────────────────
#   SIGNALS
# ──────────────────────────────────────────────────────────────
signal player_joined(player_id: int)
signal player_left(player_id: int)

# ──────────────────────────────────────────────────────────────
#   LEBENSZYKLUS
# ──────────────────────────────────────────────────────────────
func _ready() -> void:
	Input.joy_connection_changed.connect(_on_device_changed)

	# Bereits verbundene Geräte hinzufügen
	for device_id in Input.get_connected_joypads():
		_on_device_connected(device_id)

# ──────────────────────────────────────────────────────────────
#   HANDLER FÜR GERÄTE
# ──────────────────────────────────────────────────────────────
func _on_device_changed(device_id: int, connected: bool) -> void:
	if connected:
		_on_device_connected(device_id)
	else:
		_on_device_disconnected(device_id)

func _on_device_connected(device_id: int) -> void:
	var p_id: int = Players.join(device_id)
	if p_id != -1:
		player_joined.emit(p_id)
		print("✅ Device", device_id, "joined as Player", p_id)
	else:
		print("❌ Device", device_id, "could not join (full or duplicate)")

func _on_device_disconnected(device_id: int) -> void:
	var p_id: int = Players.get_player_for_device(device_id)
	if p_id != -1:
		Players.leave_by_device(device_id)
		player_left.emit(p_id)
		print("🚪 Device", device_id, "disconnected from Player", p_id)

# ──────────────────────────────────────────────────────────────
#   MANUELLE SPIELER-STEUERUNG (OPTIONAL)
# ──────────────────────────────────────────────────────────────
func join_keyboard() -> void:
	var p_id: int = Players.join(0) # 0 = Tastatur
	if p_id != -1:
		player_joined.emit(p_id)
		print("⌨ Keyboard joined as Player", p_id)

func leave_keyboard() -> void:
	var p_id: int = Players.get_player_for_device(0)
	if p_id != -1:
		Players.leave_by_device(0)
		player_left.emit(p_id)
		print("⌨ Keyboard left Player", p_id)
