extends PanelContainer

const TrackingInput = preload("res://lib/tracking/tracker.gd").Inputs
const TrackingMeta = preload("res://lib/tracking/tracker.gd").Meta
const ParameterSetting = preload("res://lib/tracking/parameter_setting.gd")

var parameter: ParameterSetting
var model_parameters: Array

func _ready() -> void:
	if parameter == null:
		return
	
	%Name.text = parameter.display_name
	%InputRangeLower.value = parameter.input_range.x
	%InputRangeUpper.value = parameter.input_range.y
	%InputLevel.min_value = %InputRangeLower.value
	%InputLevel.max_value = %InputRangeUpper.value
	%InputRangeClamp.button_pressed = parameter.clamp_output
	%InputRangeLower.value_changed.connect(
		func (value):
			parameter.input_range.x = value
			%InputLevel.min_value = value
	)
	%InputRangeUpper.value_changed.connect(
		func (value):
			parameter.input_range.y = value
			%InputLevel.max_value = value
	)
	%OutputRangeLower.value = parameter.output_range.x
	%OutputRangeUpper.value = parameter.output_range.y
	%OutputLevel.min_value = %OutputRangeLower.value
	%OutputLevel.max_value = %OutputRangeUpper.value
	%OutputRangeClamp.button_pressed = parameter.clamp_output
	%OutputRangeLower.value_changed.connect(
		func (value):
			parameter.output_range.x = value
			%OutputLevel.min_value = value
	)
	%OutputRangeUpper.value_changed.connect(
		func (value):
			parameter.output_range.y = value
			%OutputLevel.max_value = value
	)
	%Smoothing.value_changed.connect(
		func (value):
			%SmoothingLabel.text = "%d" % value
	)
	%Smoothing.value = parameter.smoothing
	%Breathe.button_pressed = parameter.breath
	%Breathe.toggled.connect(
		func (pressed):
			parameter.breath = pressed
	)
	%Blink.button_pressed = parameter.blink
	%Blink.toggled.connect(
		func (pressed):
			parameter.blink = pressed
	)
	
	for idx in range(len(model_parameters)):
		if model_parameters[idx] == parameter.output_parameter:
			%OutputTarget.select(idx)

	parameter.changed.connect(
		func (field, old_value, new_value):
			match field:
				"input_parameter":
					_update_input(new_value)
				"model_parameter":
					_update_output(new_value)
	)
	
	_update_input(parameter.input_parameter)
	_update_output(parameter.model_parameter)

func _update_input(input_parameter: TrackingInput):
	var meta = TrackingMeta.get(input_parameter, {})
	var value_range = meta.get("range", Vector2(0, 1))
	%InputSource.text = meta.get("name", TrackingInput.keys()[input_parameter].to_pascal_case())
	
func _update_output(parameter_definition: Dictionary):
	if parameter == null:
		%OutputTarget.text = ""
		%OutputLevel.min_value = 0
		%OutputLevel.max_value = 1
	else:
		%OutputTarget.text = parameter_definition.name
		%OutputLevel.min_value = parameter_definition.min
		%OutputLevel.max_value = parameter_definition.max
