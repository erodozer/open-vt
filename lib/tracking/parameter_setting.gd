extends RefCounted

const TrackingInput = preload("./tracker.gd").Inputs
const TrackingMeta = preload("./tracker.gd").Meta

var name: String
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
		
var model_parameter: Dictionary :
	set(v):
		var old = model_parameter
		model_parameter = v
		changed.emit("model_parameter", old, v)
		if v != null:
			self.output_parameter = model_parameter.name
			self.value = model_parameter.default
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

var value: float = 0

signal changed(field, old_value, new_value)

func scale_value(input: float) -> float:
	return lerp(
		output_range.x, output_range.y,
		inverse_lerp(
			input_range.x, input_range.y, input
		)
	)

func serialize() -> Dictionary:
	# translate input enum back to unity vts name
	var pname: String
	for param in TrackingInput:
		var input = TrackingInput[param]
		var meta = TrackingMeta.get(input, {})
		if input == self.input_parameter:
			pname = meta.get("name", param.to_pascal_case())
			break
			
	return {
		"Name": display_name,
		"Input": pname,
		"InputRangeLower": input_range.x,
		"InputRangeUpper": input_range.y,
		"OutputLive2D": output_parameter,
		"OutputRangeLower": output_range.x,
		"OutputRangeUpper": output_range.y,
		"ClampInput": clamp_input,
		"ClampOutput": clamp_output,
		"UseBreathing": breath,
		"UseBlinking": blink,
		"Smoothing": smoothing,
		"Minimized": minimized
	}

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
