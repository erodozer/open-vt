extends "../vt_action.gd"

const TrackingInput = preload("res://lib/tracking/parameter_setting.gd").TrackingInput
const TrackingSystem = preload("res://lib/tracking/tracking_system.gd")

@onready var input: OptionButton = %Input

var parameter
var value

var a: TrackingInput = TrackingInput.UNSET

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
	%Output/Value.text = "%.2f" % value
	
	if old_value != value:
		slot_updated.emit(1)

func _on_input_item_selected(index: int) -> void:
	parameter = TrackingInput.values()[index]
