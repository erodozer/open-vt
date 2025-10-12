extends "res://lib/tracking/tracker.gd"

@onready var bus = AudioServer.get_bus_index("VoiceInput")

var enabled = true :
	set(v):
		if not self.is_node_ready():
			return
		AudioServer.set_bus_effect_enabled(bus, 0, v)
	get():
		return AudioServer.is_bus_effect_enabled(bus, 0)

func _ready() -> void:
	Registry.add_parameter("VOICE_VOLUME", Vector2(0, 1), 0.0)
	Registry.add_parameter("VOICE_FREQUENCY", Vector2(0, 1), 0.0)
	Registry.add_parameter("VOICE_VOLUME_PLUS_MOUTH_OPEN", Vector2(0, 1), 0.0)
	Registry.add_parameter("VOICE_FREQUENCY_PLUS_MOUTH_SMILE", Vector2(0, 1), 0.0)
	
	Registry.add_parameter("VOICE_A", Vector2(0, 1), 0.0)
	Registry.add_parameter("VOICE_E", Vector2(0, 1), 0.0)
	Registry.add_parameter("VOICE_I", Vector2(0, 1), 0.0)
	Registry.add_parameter("VOICE_O", Vector2(0, 1), 0.0)
	Registry.add_parameter("VOICE_U", Vector2(0, 1), 0.0)
	Registry.add_parameter("VOICE_SILENCE", Vector2(0, 1), 0.0)
	
func _process(_delta: float) -> void:
	var vol = AudioServer.get_bus_peak_volume_left_db(bus, 0)
	
	# TOOD figure out how to parse other voice frequency values, until then rely on input from VTS
	parameters = {
		Inputs.VOICE_VOLUME: db_to_linear(vol)
	}
