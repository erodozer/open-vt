extends "../vt_action.gd"

const TrackingInput = preload("res://lib/tracking/tracker.gd").Inputs
const TrackingMeta = preload("res://lib/tracking/tracker.gd").Meta
const TrackingSystem = preload("res://lib/tracking/tracking_system.gd")

const VALUE_SLOT = 4

@onready var input: OptionButton = %Parameter

var parameter: TrackingInput = TrackingInput.UNSET :
	set(v):
		if input == null:
			return
		
		parameter = v
		input.select(v)
		var meta = TrackingMeta.get(parameter, {})
		var range = meta.get("range", Vector2(0, 1))
		
var value: float = 0.0 :
	set(v):
		value = v
		%Output/Value.value = v

var clamp_enabled: bool = false :
	get():
		return %ClampToggle.button_pressed
	set(v):
		%ClampToggle.set_pressed_no_signal(v)
var clamp_range: Vector2 = Vector2(0, 1) :
	get():
		return Vector2(
			%Input/MinValue.value,
			%Input/MaxValue.value
		)
	set(v):
		%Input/MinValue.value = v.x
		%Input/MaxValue.value = v.y

func _ready() -> void:
	for i in TrackingInput:
		input.add_item(i)
	input.selected = 0
	_on_input_item_selected(0)
		
	var tracking: TrackingSystem = get_tree().get_first_node_in_group("system:tracking")
	if tracking:
		tracking.parameters_updated.connect(_on_parameters_updated)

func _on_parameters_updated(parameters):
	var old_value = value
	value = parameters.get(parameter, 0.0)
	
	if old_value != value:
		slot_updated.emit(0)

func _on_input_item_selected(index: int) -> void:
	parameter = TrackingInput.values()[index]

func load_from_vts(data: Dictionary):
	# display_name = data["Name"]
	var input_name = data["Input"]
	for param in TrackingInput:
		var i = TrackingInput[param]
		var meta = TrackingMeta.get(i, {})
		var pname = meta.get("name", param.to_pascal_case())
		if input_name == pname:
			parameter = i
			
	var meta = TrackingMeta.get(parameter, {})
	var default_range = meta.get("range", Vector2(0, 1))
	clamp_enabled = data.get("ClampInput", false)
	clamp_range = Vector2(
		data.get("InputRangeLower", default_range.x),
		data.get("InputRangeUpper", default_range.y)
	)

func get_value(_slot):
	var value: float = self.value
	var range = self.clamp_range
	if %ClampToggle.pressed:
		value = clampf(value, range.x, range.y)
	
	return inverse_lerp(range.x, range.y, value)
