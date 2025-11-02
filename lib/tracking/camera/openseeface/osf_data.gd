extends RefCounted

const Math = preload("res://lib/utils/math.gd")
const BufferedReader = preload("res://lib/utils/buffered_reader.gd")

const nPoints = 68
const nPoints3D = nPoints + 2
const packetFrameSize = 8 + 4 + 2 * 4 + 2 * 4 + 1 + 4 + 3 * 4 + 3 * 4 + 4 * 4 + 4 * 68 + 4 * 2 * 68 + 4 * 3 * 70 + 4 * 14

const RIGHT_EYE_CENTER = 68
const LEFT_EYE_CENTER = 69

var time: float
var id: int
var cameraResolution: Vector2
var rightEyeOpen: float
var leftEyeOpen: float
var rightGaze: Quaternion
var leftGaze: Quaternion
var got3DPoints: bool
var fit3DError: float
var rotation: Vector3
var translation: Vector3
var rawQuaternion: Quaternion
var rawEuler: Vector3
var confidence: Array[float]
var points: Array[Vector2]
var points3D: Array[Vector3]

# features
var eyeLeft: float
var eyeRight: float
var eyebrowSteepnessLeft: float
var eyebrowUpDownLeft: float
var eyebrowQuirkLeft: float
var eyebrowSteepnessRight: float
var eyebrowUpDownRight: float
var eyebrowQuirkRight: float
var mouthCornerUpDownLeft: float
var mouthCornerUpDownRight: float
var mouthCornerInOutLeft: float
var mouthCornerInOutRight: float
var mouthOpen: float
var mouthWide: float

var eyeLeftXY: Vector2 :
	get:
		return Math.v32xy(Vector3.FORWARD * leftGaze).normalized()
var eyeRightXY: Vector2 :
	get:
		return Math.v32xy(Vector3.FORWARD * rightGaze)
		

func _init() -> void:
	confidence.resize(nPoints)
	points.resize(nPoints)
	points3D.resize(nPoints3D)
	
func swapX(v: Vector3) -> Vector3:
	v.x = -v.x
	return v
	
func read_osf_data(packet:PackedByteArray):
	var b = BufferedReader.new(packet)
	
	time = b.read_double()
	id = b.read_int()

	cameraResolution = b.read_vector2()
	rightEyeOpen = b.read_float()
	leftEyeOpen = b.read_float()
	
	got3DPoints = b.read_bool()

	fit3DError = b.read_float()
	rawQuaternion = b.read_quaternion()
	var convertedQuaternion = Quaternion(-rawQuaternion.x, -rawQuaternion.y, rawQuaternion.z, rawQuaternion.w)
	rawEuler = b.read_vector3();

	rotation = Vector3(rawEuler);
	rotation.z = fmod(rotation.z - 90, 360)
	if rotation.x < 0:
		rotation.x += 360
	rotation.x -= 180
	
	var x = b.read_float()
	var y = b.read_float()
	var z = b.read_float()
	translation = Vector3(y, -x, z)

	for i in range(nPoints):
		confidence[i] = b.read_float()

	for i in range(nPoints):
		points[i] = b.read_vector2()
		
	for i in range(nPoints + 2):
		points3D[i] = b.read_vector3()
	
	rightGaze = Quaternion.from_euler(swapX(points3D[66]) - swapX(points3D[68])) * Quaternion(Vector3.RIGHT, PI) * Quaternion(Vector3.FORWARD, PI)
	leftGaze = Quaternion.from_euler(swapX(points3D[67]) - swapX(points3D[69])) * Quaternion(Vector3.RIGHT, PI) * Quaternion(Vector3.FORWARD, PI)
	
	eyeLeft = b.read_float()
	eyeRight = b.read_float()
	eyebrowSteepnessLeft = b.read_float()
	eyebrowUpDownLeft = b.read_float()
	eyebrowQuirkLeft = b.read_float()
	eyebrowSteepnessRight = b.read_float()
	eyebrowUpDownRight = b.read_float()
	eyebrowQuirkRight = b.read_float()
	mouthCornerUpDownLeft = b.read_float()
	mouthCornerInOutLeft = b.read_float()
	mouthCornerUpDownRight = b.read_float()
	mouthCornerInOutRight = b.read_float()
	mouthOpen = b.read_float()
	mouthWide = b.read_float()
