# GDScript implementation of 1€ filter
# based on: https://github.com/patrykkalinowski/godot-xr-kit
# Original work: https://gery.casiez.net/1euro/

extends RefCounted

var min_cutoff: float
var beta: float
var d_cutoff: float
var x_filter: LowPassFilter
var dx_filter: LowPassFilter
var first_time: bool = true
var last_update: float = 0

func _init(cutoff, beta_) -> void:
	min_cutoff = cutoff
	beta = beta_
	d_cutoff = 1.0
	x_filter = LowPassFilter.new()
	dx_filter = LowPassFilter.new()

func alpha(rate: float, cutoff: float) -> float:
	var te = 1.0 / rate
	var tau: float = 1.0 / (2.0 * PI * cutoff)
	
	return 1.0 / (1.0 + tau / te)

func filter(value, time: float = Time.get_unix_time_from_system()) -> float:
	if min_cutoff < 0:
		return value
		
	var rate = time - last_update
	var dx: float = 0 if first_time else (value - x_filter.last_value) * rate
	first_time = false
	last_update = time
	
	var edx: float = dx_filter.filter(dx, alpha(rate, d_cutoff))
	var cutoff: float = min_cutoff + beta * abs(edx)
	return x_filter.filter(value, alpha(rate, cutoff))

class LowPassFilter:
	var last_value: float
	
	func _init() -> void:
		last_value = 0
	
	func filter(value: float, alpha: float) -> float:
		var result = alpha * value + (1 - alpha) * last_value
		last_value = result

		return result
