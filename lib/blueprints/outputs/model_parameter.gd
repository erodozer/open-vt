extends "../vt_action.gd"

const Serializers = preload("res://lib/utils/serializers.gd")

@onready var input: OptionButton = %Parameters

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
			return input.get_item_text(parameter)
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
		if value == v:
			return
		value = v
		%Input/Value.set_value_no_signal(v)
		_dirty = true

var _dirty = false
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for m in model.get_property_list():
		if m.name.begins_with("parameters/"):
			input.add_item(m.name.trim_prefix("parameters/"))
			input.set_item_metadata(input.item_count - 1, m)
	input.select(parameter)

func bind(slot: int, node: GraphNode) -> void:
	if slot == 0:
		%Input/Value.editable = false

func unbind(slot: int, node: GraphNode) -> void:
	if slot == 0:
		%Input/Value.editable = true

func reset_value(slot: int) -> void:
	if parameter < 0 or model_parameter.is_empty():
		return
	var id = "parameters/%s" % model_parameter
	value = model.property_get_revert(id)
	
func get_type() -> StringName:
	return &"model_parameter"
	
func serialize():
	return {
		"parameter": model_parameter,
		"clamp": clamp_enabled,
		"range": Serializers.RangeSerializer.to_json(clamp_range),
		"invert": invert_value
	}
	
func deserialize(data: Dictionary):
	for i in input.item_count:
		if input.get_item_text(i) == data.parameter:
			parameter = i
	
	clamp_enabled = data.get("clamp", false)
	var value_range = Serializers.RangeSerializer.from_json(data.get("range"))
	if value_range.x > value_range.y:
		clamp_range = Vector2(value_range.y, value_range.x)
		invert_value = true
	else:
		invert_value = data.get("invert", false)
		clamp_range = value_range

func load_from_vts(data: Dictionary):
	var parameters = model.get_property_list().filter(
		func (prop):
			return (prop.name as String).begins_with("parameters/")
	).map(
		func (prop):
			var hint: PackedStringArray = prop.hint_string.split(",")
			var value_range = Vector2(hint[0].to_float(), hint[1].to_float())
			return {
				"name": prop.name.trim_prefix("parameters/"),
				"value_range": value_range
			}
	).reduce(
		func (acc, p):
			acc[p.name] = p
			return acc,
		{}
	)
	parameter = parameters.keys().find(data["OutputLive2D"])
	if parameter == -1:
		return
	
	var definition = parameters.values()[parameter]
	model_parameter = definition.name
	
	var output_range = definition.value_range
	if output_range.x > output_range.y:
		invert_value = true
		clamp_range = Vector2(output_range.y, output_range.x)
	else:
		invert_value = false
		clamp_range = output_range
	clamp_enabled = data.get("ClampOutput", false)
	reset_value(0)

func update_value(_slot: int, v: float) -> void:
	if input.get_selected_metadata() == null:
		return
	
	v = lerp(clamp_range.x, clamp_range.y, v)
	
	if invert_value:
		v = remap(v, clamp_range.x, clamp_range.y, clamp_range.y, clamp_range.x)
	
	if clamp_enabled:
		v = clampf(v, clamp_range.x, clamp_range.y)
	
	value = v
	
func _update_model():
	if model_parameter.is_empty():
		return
	if not _dirty:
		return

	model.set(model_parameter, value)
	_dirty = false
	
func _process(_delta: float) -> void:
	_update_model()
	
func _on_reset_button_pressed() -> void:
	invert_value = false
	if not model_parameter.is_empty():
		clamp_range = Vector2(input.get_selected_metadata().min, input.get_selected_metadata().max)

func _on_manual_value_changed(v: float) -> void:
	value = v
