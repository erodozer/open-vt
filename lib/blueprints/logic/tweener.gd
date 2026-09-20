extends VtAction

var duration: float = 1.0 :
	get():
		return %Duration.value
var transition: Tween.TransitionType = Tween.TransitionType.TRANS_LINEAR :
	get():
		return %Transition.get_selected_id()
var easing: Tween.EaseType = Tween.EASE_IN_OUT :
	get():
		return %Easing.get_selected_id()

var _prev : float = 0
var _changed: float = 0
var a : float = 0.0 :
	set(v):
		_prev = a
		_changed = Time.get_ticks_msec()
		a = v
		%Input.value = v

var b : float = 0.0 :
	set(v):
		b = v
		%Output.value = v

func get_type() -> StringName:
	return &"tweener"
	
func serialize():
	return {
		"duration": duration,
		"transition": transition,
		"easing": easing
	}

func deserialize(data):
	%Duration.value = data.get("duration", 1.0)
	%Transition.select(data.get("transition", Tween.TransitionType.TRANS_LINEAR))
	%Easing.select(data.get("easing", Tween.EaseType.EASE_IN_OUT))

func get_input_slot_by_port(port: int) -> int:
	match port:
		0:
			return 1
		_:
			return -1

func get_input_port_by_name(slot: StringName) -> int:
	match slot.to_lower():
		"value":
			return 0
		_:
			return -1
	
func get_output_slot_by_port(port: int) -> int:
	match port:
		0:
			return 1
		_:
			return -1

func get_output_port_by_name(slot: StringName) -> int:
	match slot.to_lower():
		"value":
			return 0
		_:
			return -1

func get_value(_slot):
	return b

func update_value(_slot, value):
	a = value

func _process(_delta: float) -> void:
	var before = b
	b = Tween.interpolate_value(
		_prev, a - _prev,
		clamp((Time.get_ticks_msec() - _changed) / 1000.0, 0, duration),
		duration, transition, easing
	)
	if before != b:
		slot_updated.emit(0)
