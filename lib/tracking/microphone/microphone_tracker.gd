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
	Registry.add_parameter("VoiceVolume", Vector2(0, 1), 0.0)
	Registry.add_parameter("VoiceFrequency", Vector2(0, 1), 0.0)
	Registry.add_parameter("VoiceVolumePlusMouthOpen", Vector2(0, 1), 0.0)
	Registry.add_parameter("VoiceFrequencyPlusMouthSmile", Vector2(0, 1), 0.0)
	
	Registry.add_parameter("VoiceA", Vector2(0, 1), 0.0)
	Registry.add_parameter("VoiceE", Vector2(0, 1), 0.0)
	Registry.add_parameter("VoiceI", Vector2(0, 1), 0.0)
	Registry.add_parameter("VoiceO", Vector2(0, 1), 0.0)
	Registry.add_parameter("VoiceU", Vector2(0, 1), 0.0)
	Registry.add_parameter("VoiceSilence", Vector2(0, 1), 0.0)
	
func _process(_delta: float) -> void:
	var vol = AudioServer.get_bus_peak_volume_left_db(bus, 0)
	
	# TOOD figure out how to parse other voice frequency values, until then rely on input from VTS
	update({
		"VoiceVolume": db_to_linear(vol)
	})
