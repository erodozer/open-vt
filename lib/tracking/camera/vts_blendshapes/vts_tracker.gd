## Tracker connecting to VTS 3rd-party API
## Instead of getting the normal VTS parameters we're used to, this API
## returns iOS BlendShapes, which can be used raw

extends "../camera_tracker.gd"

const BidirectionalTracker = preload("res://lib/tracking/net/bidirectional_tracker.gd")

var server: BidirectionalTracker

var poller: Timer

func _ready():
	super._ready()
	
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
		_data_received(msg)

func _data_received(data: Dictionary):
	var parameters = {}
	for parameter in data.BlendShapes:
		parameters[parameter.k] = parameter.v
		
	update(parameters)
