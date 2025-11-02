extends "../camera_tracker.gd"

const OpenSeeData = preload("./osf_data.gd")
const UdpTracker = preload("res://lib/tracking/net/udp_tracker.gd")

# controls
var blink_sync: bool = false
var server: UdpTracker
signal data_received(data: OpenSeeData)

func _ready():
	super._ready()
	server = UdpTracker.new()
	server.name = "OSFSocket"
	server.packet_received.connect(_packet_received)
	data_received.connect(_data_received)
	add_child(server)

func create_config() -> Node:
	var panel = preload("./osf_config.tscn").instantiate()
	panel.tracker = self
	return panel

func _packet_received(data: PackedByteArray):
	var osf_data = OpenSeeData.new()
	osf_data.read_osf_data(data)
	
	data_received.emit(osf_data)

func _data_received(data: OpenSeeData):
	var eyeLeft = data.eyeLeftXY
	var eyeRight = data.eyeRightXY
	
	# sync blinking (disables winking)
	var leftOpen = data.leftEyeOpen
	var rightOpen = data.rightEyeOpen
	if blink_sync:
		leftOpen = rightOpen
		
	update({
		"FacePositionX": clampf(data.translation.x, -15, 15),
		"FacePositionY": clampf(data.translation.y, -15, 15),
		"FacePositionZ": clampf(data.translation.z, -10, 10),
		"FaceAngleX": clampf(data.rotation.y, -30, 30),
		"FaceAngleY": clampf(-data.rotation.x, -30, 30),
		"FaceAngleZ": clampf(data.rotation.z, -30, 30),
		"MouthOpen": clampf(data.mouthOpen, 0.0, 1.0),
		"MouthSmile": clampf(data.mouthWide, 0.0, 1.0),
		"EyeOpenLeft": leftOpen,
		"EyeOpenRight": rightOpen,
		"EyeLeftX": eyeLeft.x,
		"EyeLeftY": eyeLeft.y,
		"EyeRightX": eyeRight.x,
		"EyeRightY": eyeRight.y,
	})
	
