extends "../vt_action.gd"

const OneEuro = preload("res://lib/utils/oneeuro_filter.gd")

var noise_filter: OneEuro = OneEuro.new(0, 1)
var smoothing: float = 0.0 :
	set(v):
		smoothing = v
		%Smoothing.set_value_no_signal(v * 100.0)
		# TODO find proper scaling values.  Based on what looked good enough using https://gery.casiez.net/1euro/InteractiveDemo/
		noise_filter = OneEuro.new(
			lerp(0.06, 0.01, smoothing),
			lerp(0.004, 0.0002, smoothing)
		)

var a : float = 0 :
	set(v):
		a = v
		%Input.value = v

var b : float = 0 :
	set(v):
		b = v
		%Output.value = v

func get_type() -> StringName:
	return &"smoothing"
	
func serialize():
	return {
		"smoothing": smoothing
	}

func deserialize(data):
	smoothing = data.get("smoothing", 0)

func get_value(_slot):
	return b

func update_value(slot, value):
	if slot != 0:
		return
	
	a = value
	
func _on_smoothing_value_changed(value: float) -> void:
	smoothing = value / 100.0

func _process(delta: float) -> void:
	# smooth the value each frame
	b = noise_filter.filter(a)
	slot_updated.emit(0)
