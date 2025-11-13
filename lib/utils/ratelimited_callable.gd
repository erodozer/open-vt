## wrap a callable, guaranteeing it's run a limited number of times.
## 
## Supplied callable must be of fire-and-forget style interface.
## ie. Should have void or discardable return value
class_name RatelimitedCallable extends RefCounted

static func oneshot(callable: Callable) -> RatelimitedCallable:
	return RatelimitedCallable.new(callable, 1)

## Indicate if the limiter has been triggered by means of the call count exceeding its limit
var called :
	get():
		return _times_called >= _call_limit
var _callable: Callable
var _call_limit: int
var _times_called: int

## fires once the limit has been exceeded.  Useful for metrics or logging
signal tripped

func _init(callable: Callable, limit: int) -> void:
	self._callable = callable
	self._call_limit = limit
	self._times_called = 0

## Resets the debounce counter state, so that it may accumulate calls again
func reset():
	_times_called = 0
	
## Runs the inner callable and increments counter state
## If the debounce threshold is exceeded, the inner callable is not run
## 
func exec(...args):
	if called:
		return
		
	_times_called += 1
	_callable.callv(args)

	if called:
		tripped.emit()
