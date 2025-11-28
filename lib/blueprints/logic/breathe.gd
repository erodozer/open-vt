extends "../vt_action.gd"

const Serializers = preload("res://lib/utils/serializers.gd")

@export var curve: Curve

var frequency: float :
	get():
		return %TimeScale.value
	set(v):
		%TimeScale.value = v

var progress: float :
	get():
		var time = pingpong(
			fmod(Time.get_ticks_msec(), frequency * 2), frequency
		) / frequency
		return curve.sample_baked(time)
		
var input: float :
	get():
		return %ProgressBar.value
	set(v):
		%ProgressBar.value = v

func get_type():
	return &"breathe"
	
func serialize():
	return {
		"frequency": frequency,
	}

func deserialize(data):
	frequency = data.get("frequency", 2000.0)
	
func get_value(_slot):
	return progress

func _process(_delta: float) -> void:
	%ProgressBar.value = progress
	slot_updated.emit(0)
