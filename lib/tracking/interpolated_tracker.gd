## Interpolated Tracker adds a degree of smoothing between values each frame
## Useful for tracking sources that have unstable intervals in which data is received,
## such as network based tracking.
extends "./tracker.gd"

const OneEuro = preload("res://lib/utils/oneeuro_filter.gd")

var mtx = Mutex.new()
var _interpolators = {}
var _previous_msec: float = Time.get_ticks_msec()
var _latest_msec: float = Time.get_ticks_msec()

var fps: float = 0.0

@export_range(0.0, 1.0) var smoothing: float = 0.2 :
	set(v):
		smoothing = v
		for euro in _interpolators:
			euro.min_cutoff = lerp(0.01, 10.0, smoothing)
			euro.beta = lerp(0.0, 0.05, smoothing)

## get fps blended parameters for stabilization
func parameters(time: float = Time.get_ticks_msec()) -> Dictionary:
	var output = {}
	mtx.lock()
	for p in _parameters:
		output[p] = _interpolators[p].filter(_parameters[p], time)
	mtx.unlock()
	return output
	
func update(updated_parameters: Dictionary):
	var now: float = Time.get_ticks_msec()
	_previous_msec = _latest_msec
	_latest_msec = now

	mtx.lock()
	for p in updated_parameters:
		if p not in _interpolators:
			_interpolators[p] = OneEuro.new(
				lerp(0.01, 10.0, smoothing),
				lerp(0.0, 0.05, smoothing)
			)
		_parameters[p] = Registry.clamp_to_range(float(updated_parameters[p]), p)
	mtx.unlock()
	
	# estimate avg sample rate
	if _latest_msec > _previous_msec:
		var delta = 1.0 / ((_latest_msec - _previous_msec) / 1000.0)
		fps += delta
		fps /= 2.0
