extends RefCounted

var cursor: int = 0
var buffer: PackedByteArray

func _init(b: PackedByteArray) -> void:
	buffer = b

func reset():
	cursor = 0
	
func seek(i: int):
	cursor = i
	
func step(i: int):
	cursor += i

func read_float() -> float:
	var x = buffer.decode_float(cursor)
	step(4)
	return x

func read_double() -> float:
	var x = buffer.decode_double(cursor)
	step(8)
	return x

func read_int() -> int:
	var x = buffer.decode_s32(cursor)
	step(4)
	return x
	
func read_bool() -> bool:
	var b = buffer[cursor]
	step(1)
	return b != 0

func read_quaternion() -> Quaternion:
	var x = read_float()
	var y = read_float()
	var z = read_float()
	var w = read_float()
	var q = Quaternion(x, y, z, w)
	return q
	
func read_vector3() -> Vector3:
	var x = read_float()
	var y = -read_float()
	var z = read_float()
	return Vector3(x, y, z)
	
func read_vector2() -> Vector2:
	var x = read_float()
	var y = read_float()
	return Vector2(x, y)
