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
	
static func v23xy(v: Vector2) -> Vector3:
	return Vector3(
		v.x, v.y, 0
	)

static func v23yz(v: Vector2) -> Vector3:
	return Vector3(
		0, v.x, v.y
	)
	
static func v23xz(v: Vector2) -> Vector3:
	return Vector3(
		v.x, 0, v.y
	)
	
static func walk_files(dir: String, extension: String) -> Array[String]:
	var files: Array[String] = []
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(extension):
			files.append(dir.path_join(f))
		
	for d in DirAccess.get_directories_at(dir):
		files.append_array(walk_files(dir.path_join(d), extension))
	
	return files

## Naive centroid calculation by looking for the average position of all vertices
## If you want an actual weighted centroid that considers the surface area and shape of a convex hull
## this is not the implementation you want.
static func centroid(points: Array) -> Vector3:
	var s: Vector3 = Vector3.ZERO
	for p in points:
		if p is Vector2:
			p = v23xy(p)
		s += p
	return s / len(points)

class RingBuffer extends RefCounted:
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

const VTS_VIEWPORT = Vector2(1280, 720)
const VTS_ASPECT = VTS_VIEWPORT.y / VTS_VIEWPORT.x
const VTS_WORLD = Vector2(100, 100) # vts appears to have a world that's 100 wide in each direction

static func world_to_vts(_v: Vector2):
	pass

static func vts_to_world(v: Vector2):
	#var xy = v / VTS_WORLD - Vector2(0.5, 0.5)
	
	return Vector2(
		lerp(0.0, VTS_VIEWPORT.x, inverse_lerp(-VTS_WORLD.x, VTS_WORLD.x, v.x)),
		# unity's y coord are flipped
		lerp(0.0, VTS_VIEWPORT.y, inverse_lerp(-VTS_WORLD.y, VTS_WORLD.y, -v.y))
	)
