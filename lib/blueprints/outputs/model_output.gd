extends "../vt_action.gd"

const Serializers = preload("res://lib/utils/serializers.gd")

var ports = {}
var bindings = {}
var binding_display = {}
var _dirty = false
	
# Called when the node enters the scene tree for the first time.
func set_model(m: VtModel):
	model = m
	var i = 0
	var label_width = 0
	var parameters = model.get_parameters()
	for property in parameters:
		var meta = parameters[property]
		var value_range: Vector2 = meta.range
		
		var box = VBoxContainer.new()
		box.name = property
		
		var l = Label.new()
		l.text = property
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.size_flags_stretch_ratio = 2.0
		box.add_child(l)
		var value_box = HBoxContainer.new()
		value_box.add_theme_constant_override("separation", 2.0)
		var min_value = SpinBox.new()
		min_value.step = 0.01
		min_value.rounded = false
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
		max_value.step = 0.01
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
		current_value.value = meta.default
		current_value.alignment = HORIZONTAL_ALIGNMENT_RIGHT
		current_value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		current_value.editable = false
		value_box.add_child(current_value)
		box.add_child(value_box)
		add_child(box)
		
		label_width = max(
			l.get_theme_default_font().get_string_size(property).x,
			l.size.x
		)
		
		binding_display[property] = current_value
					
		var slot = get_child_count()-1
		set_slot_enabled_left(slot, true)
		set_slot_type_left(slot, SlotType.NUMERIC)
		ports[property.to_lower()] = i
		
		# do initial reset of all parameters
		# will be cleared after first update
		bindings[property] = meta.default
		i += 1
			
	# readjust sizes for columns to match
	for row in get_children():
		var label = row.get_child(0)
		label.size.x = label_width
	model = m
	_dirty = true

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
	return ports.get(slot.to_lower(), -1)

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
	var value_range: Vector2 = model.get("parameters/%s/range" % [parameter])
	bindings[parameter] = lerp(value_range.x, value_range.y, v as float)
	_dirty = true
	
func _update_model():
	if not _dirty:
		return
	
	for p in bindings:
		binding_display[p].value = bindings[p]
		model.set("parameters/%s" % [p], bindings[p])
	_dirty = false
	bindings.clear()
	
func _process(_delta: float) -> void:
	_update_model()
