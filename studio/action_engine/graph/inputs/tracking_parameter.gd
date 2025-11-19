extends "../vt_action.gd"

const Serializers = preload("res://lib/utils/serializers.gd")
const TrackingSystem = preload("res://lib/tracking/tracking_system.gd")

const VALUE_SLOT = 1

@onready var input: OptionButton = %Parameter

var parameter: String = "unset" :
	get():
		if input == null:
			return "unset"
		return parameter
	set(v):
		if input == null:
			return
		
		parameter = v
		var idx = Registry.parameters().find_custom(
			func (p):
				return p.id == v
		)
		input.select(idx)
		value = Registry.parameters()[idx].get("default_value", 0.0)
		
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
	for p in Registry.parameters():
		input.add_item(p.id)
		
	var tracking: TrackingSystem = get_tree().get_first_node_in_group("system:tracking")
	if tracking:
		tracking.parameters_updated.connect(_on_parameters_updated)

func get_type() -> StringName:
	return "tracking_parameter"
	
func serialize():
	return {
		"parameter": parameter,
		"clamp": clamp_enabled,
		"range": Serializers.RangeSerializer.to_json(clamp_range),
		"invert": invert_value
	}
	
func deserialize(data):
	for i in input.item_count:
		if input.get_item_text(i) == data.parameter:
			parameter = data.parameter
			break
	
	var meta = Registry.get(parameter)
	
	clamp_enabled = data.get("clamp", false)
	
	var default_range = meta.get("range", Vector2(0, 1))
	var value_range = Serializers.RangeSerializer.from_json(data.get("range"), default_range)
	if value_range.x > value_range.y:
		value_range = Vector2(value_range.y, value_range.x)
		invert_value = true
	else:
		invert_value = meta.get("invert", false)
		clamp_range = value_range

func _on_parameters_updated(parameters, delta):
	var old_value = value
	var new_value = parameters.get(parameter, 0.0)
		
	value = new_value
	slot_updated.emit(0)

func load_from_vts(data: Dictionary):
	# display_name = data["Name"]
	var input_name = data["Input"]
	var meta: Dictionary = {}
	for param in Registry.parameters():
		if input_name == param.id:
			parameter = param.id
			meta = param
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
	var out: float = self.value
	var in_range = Registry.get(parameter).range
	if self.invert_value:
		out = remap(out, in_range.x, in_range.y, in_range.y, in_range.x)
	if self.clamp_enabled:
		out = clampf(out, clamp_range.x, clamp_range.y)
		
	out = inverse_lerp(clamp_range.x, clamp_range.y, out)
	%Output/Value.value = out
	return out

func _on_reset_button_pressed() -> void:
	clamp_range = Registry.get(parameter).range
