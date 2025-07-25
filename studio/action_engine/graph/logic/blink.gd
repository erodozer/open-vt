extends "../vt_action.gd"

@export var curve: Curve

var blinking: float

var frequency: Vector2 :
	get():
		return Vector2(
			%MinTimeScale.value,
			%MaxTimeScale.value
		)
	set(v):
		%MinTimeScale.value = v.x
		%MaxTimeScale.value = v.y
var speed: float :
	get():
		return %Speed.value
	set(v):
		%Speed.value = v

var progress: float :
	get():
		var now = Time.get_ticks_msec()
		if now > blinking - (speed * 2):
			return 1.0 - curve.sample_baked(
				inverse_lerp(
					0.0, speed,
					pingpong(
						(blinking - now), speed
					)
				)
			)
		return 1.0

func get_value(_slot) -> float:
	return progress

func _process(delta: float) -> void:
	var now = Time.get_ticks_msec()
	if blinking < now:
		blinking = now + randf_range(frequency.x, frequency.y) + speed
	
	%ProgressBar.value = progress
	slot_updated.emit(0)
