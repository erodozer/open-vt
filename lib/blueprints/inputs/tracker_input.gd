extends "../vt_action.gd"

const TrackingSystem = preload("res://lib/tracking/tracking_system.gd")

const VALUE_SLOT = 1

var kind = &"Camera" :
	set(g):
		kind = g
		self.title = "%s Tracking" % [g]
		
		var i = 0
		for p in Registry.parameters_in_group(g):
			var value_range = Registry.get(p).range
			var box = HBoxContainer.new()
			box.name = p
			
			var l = Label.new()
			l.mouse_filter = Control.MOUSE_FILTER_PASS
			l.text = p
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			l.size_flags_stretch_ratio = 2.0
			l.tooltip_text = "[%1.2f, %1.2f]" % [value_range.x, value_range.y]
			var current_value = LineEdit.new()
			current_value.alignment = HORIZONTAL_ALIGNMENT_RIGHT
			current_value.editable = false
			box.add_child(current_value)
			box.add_child(l)
			
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

func can_spawn(graph: GraphEdit):
	return not graph.find_children("*", "VtAction", false).any(
		func (n):
			return n.get_type() == self.get_type() and n.kind == self.kind
	)

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
			value_displays[p].text = "%1.2f" % parameters[p]
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
	var parameter: StringName = get_output_slot_name(slot)
	var out: float = values[parameter]
	var value_range = Registry.get(parameter).range
	
	return Vector3(value_range.x, value_range.y, out)
