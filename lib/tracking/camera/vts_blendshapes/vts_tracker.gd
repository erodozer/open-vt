## Tracker connecting to VTS 3rd-party API
## Instead of getting the normal VTS parameters we're used to, this API
## returns iOS BlendShapes, which can be used raw

extends "../blendshape_tracker.gd"

const BidirectionalTracker = preload("res://lib/tracking/net/bidirectional_tracker.gd")
const Serializers = preload("res://lib/utils/serializers.gd")

class TrackingData:
	@export var Position: Vector3 = Vector3.ZERO
	@export var Rotation: Vector3 = Vector3.ZERO
	
	# dict = { k: str, v: float }
	@export var BlendShapes: Array = []

var server: BidirectionalTracker

var poller: Timer

func _ready():
	server = BidirectionalTracker.new()
	server.host = "0.0.0.0"
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
	panel.tracker = self
	panel.server = server
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
		"FacePositionY": data.Position.y * -1, # Y & Z coordinates are flipped
		"FacePositionZ": data.Position.z * -1,
		"FaceAngleX": data.Rotation.x,
		"FaceAngleY": data.Rotation.y * -1,
		"FaceAngleZ": data.Rotation.z * -1,
	}
	for parameter in data.BlendShapes:
		# VTS uses different names for each blendshape
		var key = parameter.k.replace("_L", "Left").replace("_R", "Right").to_pascal_case()
		parameters[key] = parameter.v
		
	update(parameters)
