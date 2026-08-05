extends "../vt_action.gd"

const Serializers = preload("res://lib/utils/serializers.gd")
const TrackingSystem = preload("res://lib/tracking/tracking_system.gd")

const VALUE_SLOT = 1

var kind = &"Camera" :
	set(g):
		kind = g
		self.title = "%s Tracking" % [g]
		
		var i = 0
		for p in Registry.parameters_in_group(g):
			var box = VBoxContainer.new()
			box.name = p
			box.add_theme_constant_override("separation", 2.0)
			var l = Label.new()
			l.text = p
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			l.size_flags_stretch_ratio = 2.0
			box.add_child(l)
			var value_box = HBoxContainer.new()
			var value_range = Registry[p].range
			var min_value = SpinBox.new()
			min_value.step = 0.01
			min_value.allow_greater = true
			min_value.allow_lesser = true
			min_value.value = value_range.x
			min_value.suffix = "min"
			min_value.alignment = HORIZONTAL_ALIGNMENT_RIGHT
			min_value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			min_value.editable = false
			value_box.add_child(min_value)
			var max_value = SpinBox.new()
			max_value.allow_greater = true
			max_value.allow_lesser = true
			min_value.step = 0.01
			max_value.value = value_range.y
			max_value.suffix = "max"
			max_value.alignment = HORIZONTAL_ALIGNMENT_RIGHT
			max_value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			max_value.editable = false
			value_box.add_child(max_value)
			var current_value = SpinBox.new()
			current_value.allow_greater = true
			current_value.allow_lesser = true
			current_value.step = 0.01
			current_value.value = Registry.get_default(p)
			current_value.alignment = HORIZONTAL_ALIGNMENT_RIGHT
			current_value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			current_value.editable = false
			value_box.add_child(current_value)
			box.add_child(value_box)
			add_child(box)
			
			var slot = get_child_count() - 1
			set_slot_enabled_right(slot, true)
			set_slot_type_right(slot, SlotType.VECTOR)
			_slot_to_output[p.to_lower()] = i
			values[p] = Registry.get_default(p)
			value_displays[p] = current_value
			i += 1
			
var values = {}
var value_displays = {}
	
func _ready() -> void:
	var tracking: TrackingSystem = get_tree().get_first_node_in_group("system:tracking")
	if tracking:
		tracking.parameters_updated.connect(_on_parameters_updated)

func get_type() -> StringName:
	return &"tracking_input"
	
func serialize():
	return {
		"type": kind
	}
	
func deserialize(data):
	kind = data.type

func _on_parameters_updated(parameters, delta):
	for p in parameters:
		if p in values:
			values[p] = parameters[p]
			value_displays[p].value = parameters[p]
			slot_updated.emit(get_output_port_by_name(p))
	
func get_input_slot_by_port(port: int) -> int:
	return -1

func get_input_port_by_name(slot: StringName) -> int:
	return -1

func get_output_slot_by_port(port: int) -> int:
	if port < 0 or port >= get_child_count():
		return -1
	return port

func get_output_port_by_name(slot: StringName) -> int:
	return _slot_to_output.get(slot.to_lower(), -1)
	
func get_value(slot: int):
	var parameter: StringName = get_slot_name(slot)
	var out: float = values[parameter]
	var value_range = Registry.get(parameter).range
	
	return Vector4(value_range.x, value_range.y, out, inverse_lerp(value_range.x, value_range.y, out))
