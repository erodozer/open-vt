extends "../vt_action.gd"

const Stage = preload("res://lib/stage.gd")

const VALUE_SLOT = 1

@onready var input: OptionButton = %Parameters
@onready var stage: Stage = get_tree().get_first_node_in_group("system:stage")

@export var breathe_curve: Curve
@export var blink_curve: Curve

var parameter: int = -1 :
	set(v):
		parameter = v
		input.selected = v
		
		#var meta = stage.active_model.parameters[parameter]
		#%Range/MinValue.min_value = meta
		
var model_parameter : String :
	get():
		var parameter = input.get_selected_metadata()
		if parameter == null:
			return ""
		return parameter.name
		
var clamp_enabled: bool :
	set(v):
		%ClampToggle.button_pressed = v
		clamp_enabled = v
		
var range: Vector2 = Vector2(0, 1) :
	get():
		return Vector2(
			%Range/MinValue.value,
			%Range/MaxValue.value
		)
	set(v):
		%Range/MinValue.value = v.x
		%Range/MaxValue.value = v.y
	
var value: float :
	set(v):
		value = v
		%Input/Value.value = v
	
var _dirty = false
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:	
	for m in stage.active_model.parameters.values():
		input.add_item(m.name)
		input.set_item_metadata(input.item_count - 1, m)

func load_from_vts(data: Dictionary):
	var model = stage.active_model
	parameter = model.parameters.values().find_custom(
		func (f):
			return f.name == data["OutputLive2D"]
	)
	
	range = Vector2(
		data["OutputRangeLower"],
		data["OutputRangeUpper"],
	)
	clamp_enabled = data.get("ClampOutput", false)
	
func update_value(_slot: int, v: float) -> void:
	var parameter = input.get_selected_metadata()
	if parameter == null:
		return
	
	var scaled = lerp(range.x, range.y, v)
	value = scaled
	
	_dirty = true
	
func _update_model():
	if model_parameter.is_empty():
		return
	if not _dirty:
		return
	
	var model = stage.active_model
	model.mixer.get_node("Tracking").set(
		model_parameter, value
	)
	_dirty = false
	
func _process(_delta: float) -> void:
	_update_model()
	
