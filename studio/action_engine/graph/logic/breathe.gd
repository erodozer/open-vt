extends "../vt_action.gd"

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
		return %Value.value
	set(v):
		%Value.value = v

var link: NodePath :
	set(v):
		link = v
		%TimeScale.disabled = v != NodePath("")

func get_value(_slot):
	return progress

func _process(_delta: float) -> void:
	%ProgressBar.value = progress
	slot_updated.emit(0)
