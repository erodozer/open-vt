extends "res://lib/tracking/net/tcp_tracker.gd"

const TrackingInput = preload("res://lib/tracking/tracker.gd").Inputs
const VtModel = preload("res://lib/model/vt_model.gd")
const Stage = preload("res://lib/stage.gd")

@onready var stage: Stage = get_tree().get_first_node_in_group("system:stage")

func _ready():
	super._ready()
	port = 25565

func create_config() -> Node:
	var panel = preload("./vts_config.tscn").instantiate()
	panel.tracker = self
	return panel

func _packet_received(packet: PackedByteArray):
	# parse Telemetry message format
	var header = packet.decode_u32(0)
	var buffer = packet.slice(4, header)
	var content = buffer.get_string_from_utf8()
	if content:
		var msg = JSON.parse_string(content)
		_update_data(msg.Data)

func _update(_delta: float) -> void:
	if stage == null:
		return

	var model: VtModel = stage.active_model
	if model == null:
		return
	
	parameters = {}
	for parameter in curr_data:
		var input_parameter = parameter.p as TrackingInput
		# data from VTS mobile is already transformed by configured model parameters on the device
		# as such it's important to be using the same model on the phone as you have loaded on open-vt
		for binding in model.studio_parameters:
			if binding.input_parameter == input_parameter:
				parameters[binding.output_parameter] = parameter.v
	
