extends RefCounted

var _backing: Array
var _cursor: int
var _size: int

func _init(size, fill = 0):
	_size = size
	_backing.resize(size)
	_backing.fill(fill)
	
func push(value):
	_backing[_cursor] = value
	_cursor = wrapi(_cursor + 1, 0, _size)
	
## most recently pushed record
func head():
	return _backing[_cursor]
	
## furthest back record in the buffer
func tail():
	return _backing[wrapi(_cursor + 1, 0, _size)]
	
## return an ordered copy of the buffer
func values() -> Array:
	var ordered = []
	var idx = _cursor
	for _i in range(_size):
		ordered.append(_backing[idx])
		idx = wrapi(idx - 1, 0, _size)
	return ordered
