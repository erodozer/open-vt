extends "../vt_action.gd"

const Serializers = preload("res://lib/utils/serializers.gd")
const TrackingInput = preload("res://lib/tracking/tracker.gd").Inputs
const TrackingMeta = preload("res://lib/tracking/tracker.gd").Meta
const TrackingSystem = preload("res://lib/tracking/tracking_system.gd")

const VALUE_SLOT = 1

@onready var input: OptionButton = %Parameter

var parameter: TrackingInput = TrackingInput.UNSET :
	get():
		if input == null:
			return TrackingInput.UNSET
		return TrackingInput.values()[input.selected]
	set(v):
		if input == null:
			return
		
		parameter = v
		input.select(v)
		# var meta = TrackingMeta.get(parameter, {})
		# var range = meta.get("range", Vector2(0, 1))
		
var value: float = 0.0 :
	set(v):
		value = v
		%Output/RawValue.value = v

var clamp_enabled: bool = false :
	get():
		return %ClampToggle.button_pressed
	set(v):
		%ClampToggle.set_pressed_no_signal(v)
var clamp_range: Vector2 = Vector2(0, 1) :
	get():
		return %Input.value
	set(v):
		%Input.value = v
		
var invert_value: bool = false :
	get():
		return %InvertToggle.button_pressed
	set(v):
		%InvertToggle.set_pressed_no_signal(v)

func _ready() -> void:
	for i in TrackingInput:
		input.add_item(i)
		
	var tracking: TrackingSystem = get_tree().get_first_node_in_group("system:tracking")
	if tracking:
		tracking.parameters_updated.connect(_on_parameters_updated)

func get_type() -> StringName:
	return "tracking_parameter"
	
func serialize():
	return {
		"parameter": input.get_item_text(parameter),
		"clamp": clamp_enabled,
		"range": Serializers.RangeSerializer.to_json(clamp_range),
		"invert": invert_value,
	}
	
func deserialize(data):
	for i in input.item_count:
		if input.get_item_text(i) == data.parameter:
			parameter = TrackingInput.values()[i]
			break
	
	var meta = TrackingMeta.get(parameter, {})
	
	clamp_enabled = data.get("clamp", false)
	
	var default_range = meta.get("range", Vector2(0, 1))
	var range = Serializers.RangeSerializer.from_json(data.get("range"), default_range)
	if range.x > range.y:
		range = Vector2(range.y, range.x)
		invert_value = true
	else:
		invert_value = meta.get("invert", false)
		clamp_range = range

func _on_parameters_updated(parameters):
	var old_value = value
	value = parameters.get(parameter, 0.0)
	
	if old_value != value:
		slot_updated.emit(0)

func load_from_vts(data: Dictionary):
	# display_name = data["Name"]
	var input_name = data["Input"]
	var meta: Dictionary = {}
	for param in TrackingInput:
		var i = TrackingInput[param]
		var m = TrackingMeta.get(i, {})
		var pname = m.get("name", param.to_pascal_case())
		if input_name == pname:
			parameter = i
			meta = m
			break
			
	var default_range = meta.get("range", Vector2(0, 1))
	clamp_enabled = data.get("ClampInput", false)
	var range = Vector2(
		data.get("InputRangeLower", default_range.x),
		data.get("InputRangeUpper", default_range.y)
	)
	if range.x > range.y:
		invert_value = true
		clamp_range = Vector2(range.y, range.x)
	else:
		invert_value = false
		clamp_range = range

func get_value(_slot):
	var value: float = self.value
	var input = TrackingMeta[parameter].range
	if self.invert_value:
		value = remap(value, input.x, input.y, input.y, input.x)
	if self.clamp_enabled:
		value = clampf(value, clamp_range.x, clamp_range.y)
		
	value = inverse_lerp(clamp_range.x, clamp_range.y, value)
	%Output/Value.value = value
	return value

func _on_reset_button_pressed() -> void:
	clamp_range = TrackingMeta[parameter].range
