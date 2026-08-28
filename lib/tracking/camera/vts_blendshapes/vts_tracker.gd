## Tracker connecting to VTS 3rd-party API
## Instead of getting the normal VTS parameters we're used to, this API
## returns iOS BlendShapes, which can be used raw

extends "res://lib/tracking/interpolated_tracker.gd"

const BidirectionalTracker = preload("res://lib/tracking/net/bidirectional_tracker.gd")
const Serializers = preload("res://lib/utils/serializers.gd")

const BlendShapes = [
	"EyeBlinkLeft",
	"EyeLookDownLeft",
	"EyeLookInLeft",
	"EyeLookOutLeft",
	"EyeLookUpLeft",
	"EyeSquintLeft",
	"EyeWideLeft",
	"EyeBlinkRight",
	"EyeLookDownRight",
	"EyeLookInRight",
	"EyeLookOutRight",
	"EyeLookUpRight",
	"EyeSquintRight",
	"EyeWideRight",
	"JawForward",
	"JawRight",
	"JawLeft",
	"JawOpen",
	"MouthClose",
	"MouthFunnel",
	"MouthPucker",
	"MouthLeft",
	"MouthRight",
	"MouthSmileLeft",
	"MouthSmileRight",
	"MouthFrownLeft",
	"MouthFrownRight",
	"MouthDimpleLeft",
	"MouthDimpleRight",
	"MouthStretchLeft",
	"MouthStretchRight",
	"MouthRollLower",
	"MouthRollUpper",
	"MouthShrugLower",
	"MouthShrugUpper",
	"MouthPressLeft",
	"MouthPressRight",
	"MouthLowerDownLeft",
	"MouthLowerDownRight",
	"MouthUpperUpLeft",
	"MouthUpperUpRight",
	"BrowDownLeft",
	"BrowDownRight",
	"BrowInnerUp",
	"BrowOuterUpLeft",
	"BrowOuterUpRight",
	"CheekPuff",
	"CheekSquintLeft",
	"CheekSquintRight",
	"NoseSneerLeft",
	"NoseSneerRight",
	"TongueOut",
]

class TrackingData:
	@export var Position: Vector3 = Vector3.ZERO
	@export var Rotation: Vector3 = Vector3.ZERO
	
	# dict = { k: str, v: float }
	@export var BlendShapes: Array[Dictionary] = []

var server: BidirectionalTracker

var poller: Timer

static func _static_init() -> void:
	for param in BlendShapes:
		Registry.add_parameter(param, Vector2.DOWN, 0.0, "iOSBlendShape")

func _ready():
	server = BidirectionalTracker.new()
	server.host = "localhost"
	server.port = 50650
	server.client_port = 21412
	server.handshake_frequency = 1
	
	server.packet_received.connect(_packet_received)
	server.try_handshake.connect(
		func (client: PacketPeerUDP):
			var err = client.put_packet(
				JSON.stringify({
					"messageType": "iOSTrackingDataRequest",
					"sentBy": "OpenVT",
					"sendForSeconds": 10,
					"ports": [server.port]
				}).to_ascii_buffer()
			)
			if err != OK:
				push_warning("[VTS] client unable to send message", err)
	)
	
	add_child(server)

func create_config() -> Node:
	var panel = preload("./vts_config.tscn").instantiate()
	panel.tracker = server
	return panel

func _packet_received(packet: PackedByteArray):
	# parse Telemetry message format
	var content = packet.get_string_from_ascii()
	if content:
		var msg = JSON.parse_string(content)
		var data: TrackingData = Serializers.ObjSerializer.from_json(msg, TrackingData.new())
		_data_received(data)

func _data_received(data: TrackingData):
	var parameters = {
		"FacePositionX": data.Position.x,
		"FacePositionY": data.Position.y,
		"FacePositionZ": data.Position.z,
		"FaceAngleX": data.Rotation.x,
		"FaceAngleY": data.Rotation.y,
		"FaceAngleZ": data.Rotation.z,
	}
	for parameter in data.BlendShapes:
		parameters[parameter.k] = parameter.v
		
	update(parameters)
