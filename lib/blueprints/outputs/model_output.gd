extends "../vt_action.gd"

const Serializers = preload("res://lib/utils/serializers.gd")

var ports = {}
var bindings = {}
var _dirty = false
	
# Called when the node enters the scene tree for the first time.
func set_model(m: VtModel):
	model = m
	var i = 0
	var label_width = 0
	for property in model.get_property_list():
		if property.name.begins_with("parameters/"):
			var n = property.name.trim_prefix("parameters/")
			var value_range = Array(property.hint_string.split(",")).map(
				func (v: String):
					return v.to_float()
			)
			
			var box = HBoxContainer.new()
			box.name = n
			box.add_theme_constant_override("separation", 2.0)
			var l = Label.new()
			l.text = n
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			l.size_flags_stretch_ratio = 2.0
			box.add_child(l)
			var min_value = SpinBox.new()
			min_value.step = 0.01
			min_value.rounded = false
			min_value.max_value = INF
			min_value.min_value = -INF
			min_value.value = value_range[0]
			min_value.suffix = "min"
			min_value.alignment = HORIZONTAL_ALIGNMENT_RIGHT
			min_value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			min_value.editable = false
			box.add_child(min_value)
			var max_value = SpinBox.new()
			max_value.max_value = INF
			max_value.min_value = -INF
			min_value.step = 0.01
			max_value.value = value_range[1]
			max_value.suffix = "max"
			max_value.alignment = HORIZONTAL_ALIGNMENT_RIGHT
			max_value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			max_value.editable = false
			box.add_child(max_value)
			add_child(box)
			
			label_width = max(
				l.get_theme_default_font().get_string_size(n).x,
				l.size.x
			)
						
			var slot = get_child_count()-1
			set_slot_enabled_left(slot, true)
			set_slot_type_left(slot, SlotType.NUMERIC)
			ports[n.to_lower()] = i
			i += 1
			
	# readjust sizes for columns to match
	for row in get_children():
		var label = row.get_child(0)
		label.size.x = label_width
	model = m

func unbind(slot: int, node: GraphNode) -> void:
	var param = get_child(slot).name
	bindings.erase(param)
	
func reset_value(slot: int) -> void:
	var param = get_child(slot).name
	var default = model.property_get_revert("parameters/%s" % [param])
	bindings[param] = default
	_dirty = true
	
func get_input_slot_by_port(port: int) -> int:
	if port < 0 or port >= get_child_count():
		return -1
	return port
	
func get_input_port_by_name(slot: StringName) -> int:
	return ports[slot.to_lower()]

func get_output_slot_by_port(port: int) -> int:
	return -1

func get_output_port_by_name(slot: StringName) -> int:
	return -1

func get_type() -> StringName:
	return &"model_output"
	
func serialize():
	return {}
	
func deserialize(data: Dictionary):
	pass
	
func update_value(slot: int, v: Variant) -> void:
	var parameter: StringName = get_slot_name(slot)
	bindings[parameter] = v as float
	_dirty = true
	
func _update_model():
	if not _dirty:
		return
	
	for p in bindings:
		model.set("parameters/%s" % [p], bindings[p])
	_dirty = false
	bindings.clear()
	
func _process(_delta: float) -> void:
	_update_model()
