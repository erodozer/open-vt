extends "res://lib/tracking/tracker.gd"

@onready var bus = AudioServer.get_bus_index("VoiceInput")

var enabled = true :
	set(v):
		if not self.is_node_ready():
			return
		AudioServer.set_bus_effect_enabled(bus, 0, v)
	get():
		return AudioServer.is_bus_effect_enabled(bus, 0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var vol = AudioServer.get_bus_peak_volume_left_db(bus, 0)
	parameters = {
		Inputs.VOICE_VOLUME: db_to_linear(vol)
	}
