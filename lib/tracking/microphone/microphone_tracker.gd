extends "res://lib/tracking/tracker.gd"

@onready var bus = AudioServer.get_bus_index("VoiceInput")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var vol = AudioServer.get_bus_peak_volume_left_db(bus, 0)
	parameters = {
		Inputs.VOICE_VOLUME: db_to_linear(vol)
	}
