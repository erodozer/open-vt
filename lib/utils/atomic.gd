extends Object

## Simple mutex protected value container
class AtomicValue:
	var guard: Mutex = Mutex.new()
	var value: Variant
		
	func store(v):
		guard.lock()
		value = v
		guard.unlock()
		
	func try_get():
		var cp = null
		if guard.try_lock():
			cp = value
			guard.unlock()
		return cp
	
