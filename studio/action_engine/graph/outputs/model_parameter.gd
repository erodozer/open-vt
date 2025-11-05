extends "../vt_action.gd"

const Serializers = preload("res://lib/utils/serializers.gd")

const VALUE_SLOT = 1

@onready var input: OptionButton = %Parameters

@export var breathe_curve: Curve
@export var blink_curve: Curve

var parameter: int = -1 :
	set(v):
		parameter = v
		if input:
			input.selected = v
		
		#var meta = stage.active_model.parameters[parameter]
		#%Range/MinValue.min_value = meta
		
var model_parameter : String :
	get():
		if input:
			var parameter = input.get_selected_metadata()
			if parameter != null:
				return parameter.name
		return ""
		
var clamp_enabled: bool :
	get():
		return %ClampToggle.button_pressed
	set(v):
		%ClampToggle.button_pressed = v
		
var clamp_range: Vector2 = Vector2(0, 1) :
	get():
		return %Range.value
	set(v):
		%Range.value = v

var invert_value: bool = false :
	get():
		return %InvertToggle.button_pressed
	set(v):
		%InvertToggle.set_pressed_no_signal(v)
			
var value: float :
	set(v):
		value = v
		%Input/Value.value = v
	
var _dirty = false
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:	
	for m in model.parameters.values():
		input.add_item(m.name)
		input.set_item_metadata(input.item_count - 1, m)
	input.select(parameter)

func get_type():
	return "model_parameter"
	
func serialize():
	return {
		"parameter": model_parameter,
		"clamp": clamp_enabled,
		"range": Serializers.RangeSerializer.to_json(clamp_range),
		"invert": invert_value,
	}
	
func deserialize(data: Dictionary):
	for i in input.item_count:
		if input.get_item_text(i) == data.parameter:
			parameter = i
	
	clamp_enabled = data.get("clamp", false)
	var range = Serializers.RangeSerializer.from_json(data.get("range"))
	if range.x > range.y:
		clamp_range = Vector2(range.y, range.x)
		invert_value = true
	else:
		invert_value = data.get("invert", false)
		clamp_range = range
	
func load_from_vts(data: Dictionary):
	parameter = model.parameters.values().find_custom(
		func (f):
			return f.name == data["OutputLive2D"]
	)
	
	var range = Vector2(
		data["OutputRangeLower"],
		data["OutputRangeUpper"],
	)
	if range.x > range.y:
		invert_value = true
		clamp_range = Vector2(range.y, range.x)
	else:
		invert_value = false
		clamp_range = range
	clamp_enabled = data.get("ClampOutput", false)
	
func update_value(_slot: int, v: float) -> void:
	var parameter = input.get_selected_metadata()
	if parameter == null:
		return
	
	v = lerp(clamp_range.x, clamp_range.y, v)
	
	if invert_value:
		v = remap(v, clamp_range.x, clamp_range.y, clamp_range.y, clamp_range.x)
	
	if clamp_enabled:
		v = clampf(v, clamp_range.x, clamp_range.y)
	
	value = v
	_dirty = true
	
func _update_model():
	if model_parameter.is_empty():
		return
	if not _dirty:
		return
	
	model.mixer.get_node("Tracking").set(
		model_parameter, value
	)
	_dirty = false
	
func _process(_delta: float) -> void:
	_update_model()
	
func _on_reset_button_pressed() -> void:
	invert_value = false
	if not model_parameter.is_empty():
		clamp_range = Vector2(input.get_selected_metadata().min, input.get_selected_metadata().max)
