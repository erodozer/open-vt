extends "../camera_tracker.gd"

const TCPTracker = preload("res://lib/tracking/net/tcp_tracker.gd")

# for compatibility with VTS and its Stream to PC functionality
# it's important to maintain exact enum order, as they are serialized by the ordinal
const Inputs = [
	"Unset",
	"FacePositionX",
	"FacePositionY",
	"FacePositionZ",
	"FaceAngleX",
	"FaceAngleY",
	"FaceAngleZ",
	"MouthSmile",
	"MouthOpen",
	"Brows",
	"TongueOut", # iOS/Android only
	"EyeOpenLeft",
	"EyeOpenRight",
	"EyeLeftX",
	"EyeLeftY",
	"EyeRightX",
	"EyeRightY",
	"CheekPuff", # iOS only
	"FaceAngry", # iOS only
	"BrowLeftY",
	"BrowRightY",
	"MousePositionX",
	"MousePositionY",
	# microphone
	"VoiceVolume",
	"VoiceFrequency",
	"VoiceVolumePlusMouthOpen",
	"VoiceFrequencyPlusMouthSmile",
	"MouthX",
	# pc only
	"HandLeftFound",
	"HandRightFound",
	"BothHandsFound",
	"HandDistance",
	"HandLeftPositionX",
	"HandLeftPositionY",
	"HandLeftPositionZ",
	"HandRightPositionX",
	"HandRightPositionX",
	"HandRightPositionX",
	"HandLeftAngleX",
	"HandLeftAngleZ",
	"HandRightAngleX",
	"HandRightAngleZ",
	"HandLeftOpen",
	"HandRightOpen",
	"HandLeftFinger1Thumb",
	"HandLeftFinger2Index",
	"HandLeftFinger3Middle",
	"HandLeftFinger4Ring",
	"HandLeftFinger5Pinky",
	"HandRightFinger1Thumb",
	"HandRightFinger2Index",
	"HandRightFinger3Middle",
	"HandRightFinger4Ring",
	"HandRightFinger5Pinky",
	# more voice
	"VoiceA",
	"VoiceI",
	"VoiceU",
	"VoiceE",
	"VoiceO",
	"VoiceSilence"
]

var server: TCPTracker

var poller: Timer

func _ready():
	super._ready()
	server = TCPTracker.new()
	server.port = 25565
	
	server.packet_received.connect(_packet_received)
	
	add_child(server)

func create_config() -> Node:
	var panel = preload("./vts_config.tscn").instantiate()
	panel.tracker = server
	return panel

func _packet_received(packet: PackedByteArray):
	# parse Telemetry message format
	var header = packet.decode_u32(0)
	var buffer = packet.slice(4, header)
	var content = buffer.get_string_from_utf8()
	if content:
		var msg = JSON.parse_string(content)
		if msg != null and "Data" in msg:
			_data_received(msg.Data)

func _data_received(data: Array):
	var param = {}
	for p in data:
		var parameter = Inputs[int(p.p)]
		param[parameter] = p.v
	update(param)
