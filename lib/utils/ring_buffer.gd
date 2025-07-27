extends RefCounted

var _backing: Array
var _cursor: int
var _size: int

func _init(size):
	_size = size
	_backing.resize(size)
	
func push(value):
	_backing[_cursor] = value
	_cursor = wrapi(_cursor + 1, 0, _size)
	
## most recently pushed record
func head():
	return _backing[_cursor]
	
## furthest back record in the buffer
func tail():
	return _backing[wrapi(_cursor + 1, 0, _size)]
	
func values() -> Array:
	return _backing
