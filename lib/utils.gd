extends Object

static func v32xy(v: Vector3) -> Vector2:
	return Vector2(
		v.x, v.y
	)

static func v32xz(v: Vector3) -> Vector2:
	return Vector2(
		v.x, v.z
	)

static func v32yz(v: Vector3) -> Vector2:
	return Vector2(
		v.y, v.z
	)

static func centroid(points: Array[Vector3]) -> Vector3:
	var s = Vector3.ZERO
	for p in points:
		s += p
	return s / len(points)

class RingBuffer:
	var _backing: Array
	var _cursor: int
	var _size: int
	
	func _init(size):
		_size = size
		_backing.resize(size)
		
	func push(value):
		_backing[_cursor] = value
		_cursor = wrapi(_cursor + 1, 0, _size)
		
	func values() -> Array:
		return _backing
