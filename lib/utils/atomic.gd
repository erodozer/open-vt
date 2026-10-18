extends Object

## Simple mutex protected value container
class AtomicValue:
	var guard: Mutex = Mutex.new()
	var value: Variant
	var dirty: bool
		
	func store(v):
		guard.lock()
		if value != v:
			value = v
			dirty = true
		guard.unlock()
		
	## gets the current stored value
	func try_get():
		var cp = null
		if guard.try_lock():
			cp = value
			guard.unlock()
		return cp
	
	## only returns a value if it has changed since the last read attempt
	func try_get_changed():
		var cp = null
		if guard.try_lock():
			if dirty:
				cp = value
				dirty = false
			guard.unlock()
		return cp
	
