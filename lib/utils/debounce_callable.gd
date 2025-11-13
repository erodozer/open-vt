## Debounce calls to a function, firing off only once a trigger theshold has been met
##
## Debouncing is similar to rate-limiting in that we prevent the inner callable from being executed.
## Whereas RatelimitedCallable prevents the inner callable from being invoked after a certain number of times,
## debouncing will ignore all attempts to execute, preserving the most recent request, and fires off once
## a trigger condition has been met.
class_name DebounceCallable extends Node

enum TriggerMode {
	TIME,
	FRAME,
	MANUAL
}

var _called: bool = false
var _last_args: Array = []

var _callable: Callable
var _trigger_mode: TriggerMode

# timer debounce
var _frequency: float = 0.0
var _last_reset: float

func _init(callable: Callable, trigger_mode: TriggerMode = TriggerMode.MANUAL, frequency: float = 1.0):
	self._callable = callable
	self._last_args = []
	self._trigger_mode = trigger_mode
	
	if trigger_mode == TriggerMode.TIME:
		self._frequency = frequency
		self._last_reset = Time.get_unix_time_from_system()
	
	# attach to main loop
	(Engine.get_main_loop() as SceneTree).process_frame.connect(_update)

func _update():
	# fire once per frame
	if _trigger_mode == TriggerMode.FRAME:
		trigger()
	
	if _trigger_mode == TriggerMode.TIME:
		var now = Time.get_unix_time_from_system()
		if now - _last_reset > _frequency:
			trigger()
		
func trigger():
	_last_reset = Time.get_unix_time_from_system()
	if not _called:
		return
	
	_callable.callv(_last_args)
	_last_args = []
	_called = false
	
func exec(...args):
	_called = true
	_last_args = args
	
	# time based debounce fire off relative to the last call
	_last_reset = Time.get_unix_time_from_system()
