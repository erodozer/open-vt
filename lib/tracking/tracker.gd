extends Node

var _previous = {}
var _previous_msec: float = Time.get_ticks_msec()
var _parameters = {}
var _latest_msec: float = Time.get_ticks_msec()

var fps: float = 0.0

@export_range(0.0, 1.0) var smoothing: float = 0.2

func create_config() -> Node:
	return null

## get fps blended parameters for stabilization
func parameters(time: float = Time.get_ticks_msec()) -> Dictionary:
	# blend ranges based on sample rate
	# we always blend with a 1 update delay
	var progress: float = clampf(
		(time - _latest_msec) / (_latest_msec - _previous_msec),
		0.0, 1.0
	)
	#progress = 1.0
	
	var output = {}
	
	for p in _parameters:
		output[p] = lerp(
			float(_previous.get(p, _parameters[p])),
			float(_parameters[p]),
			progress
		)
	
	return output

func update(updated_parameters: Dictionary):
	var now: float = Time.get_ticks_msec()
	_previous = _parameters
	_previous_msec = _latest_msec
	_latest_msec = now
	_parameters = {}

	for p in updated_parameters:
		_parameters[p] = lerp(
			float(_previous.get(p, 0)),
			float(updated_parameters[p]),
			1.0 - smoothing
		)
	
	# estimate avg sample rate
	var delta = 1.0 / ((_latest_msec - _previous_msec) / 1000.0)
	fps += delta
	fps /= 2.0
