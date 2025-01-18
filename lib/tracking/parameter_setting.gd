extends Node

const TrackingInput = preload("./tracker.gd").Inputs
const TrackingMeta = preload("./tracker.gd").Meta

var display_name: String :
	set(v):
		var old = display_name
		display_name = v
		changed.emit("display_name", old, v)
		
var input_parameter: TrackingInput:
	set(v):
		var old = input_parameter
		input_parameter = v
		changed.emit("input_parameter", old, v)
		
var output_parameter: String :
	set(v):
		var old = output_parameter
		output_parameter = v
		if name == "":
			name = "Unset"
		else:
			name = v
		changed.emit("output_parameter", old, v)
		
var model_parameter: GDCubismParameter :
	set(v):
		var old = model_parameter
		model_parameter = v
		changed.emit("model_parameter", old, v)
		if v != null:
			self.output_parameter = model_parameter.id
		else:
			self.output_parameter = ""
	
var input_range: Vector2 = Vector2(0, 1) :
	set(v):
		var old = input_range
		input_range = v
		changed.emit("input_range", old, v)
		
var output_range: Vector2 = Vector2(0, 1) :
	set(v):
		var old = output_range
		output_range = v
		changed.emit("output_range", old, v)
		
var clamp_input: bool = false
var clamp_output: bool = false
var breath: bool = false
var blink: bool = false
@export_range(0, 100) var smoothing: int = 15
var minimized: bool = false

signal changed(field, old_value, new_value)

func value(input: float) -> float:
	if input_parameter == TrackingInput.UNSET:
		return output_range.x
	
	return lerp(
		output_range.x, output_range.y,
		inverse_lerp(
			input_range.x, input_range.y, input
		)
	)

func update(tracking_data: Dictionary):
	# skip paramters that haven't been fully configured
	if output_parameter == null or model_parameter == null:
		return
	# skip parameters that we do not yet support binding to
	var raw_value = tracking_data.get(input_parameter, 0)
	var adj_value = value(raw_value)
	model_parameter.value = adj_value

func serialize() -> Dictionary:
	return {}

func deserialize(data: Dictionary) -> bool:
	display_name = data["Name"]
	var input_name = data["Input"]
	for param in TrackingInput:
		var input = TrackingInput[param]
		var meta = TrackingMeta.get(input, {})
		var pname = meta.get("name", param.to_pascal_case())
		if input_name == pname:
			input_parameter = input
			
	output_parameter = data["OutputLive2D"]
	name = output_parameter
	input_range = Vector2(
		data["InputRangeLower"],
		data["InputRangeUpper"]
	)
	output_range = Vector2(
		data["OutputRangeLower"],
		data["OutputRangeUpper"],
	)
	clamp_input = data["ClampInput"]
	clamp_output = data["ClampOutput"]
	breath = data["UseBreathing"]
	blink = data["UseBlinking"]
	smoothing = data["Smoothing"]
	minimized = data["Minimized"]
	
	return true
