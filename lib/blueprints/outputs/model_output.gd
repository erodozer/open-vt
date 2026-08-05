extends "../vt_action.gd"

const Serializers = preload("res://lib/utils/serializers.gd")

var ports: Dictionary[String, int] = {}
var slots: Dictionary[int, int] = {}
var port_count = 0
var bindings = {}
var binding_display = {}
var _dirty = false
var _refresh = false
	
# Called when the node enters the scene tree for the first time.
func set_model(m: VtModel):
	model = m
	build_slots()
	
	model.modifier_updated.connect(
		func (field: StringName, _new, _old):
			if field.begins_with("modifiers/parameters"):
				self.refresh_fields()
	)
	
func build_slots():
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
		slots[i] = slot
		
		# do initial reset of all parameters
		# will be cleared after first update
		bindings[property] = meta.default
		
		var hidden = model.get("modifiers/parameters/%s/hidden" % property)
		box.visible = not hidden
		if not hidden:
			i += 1
			
	# readjust sizes for columns to match
	for row in get_children():
		var label = row.get_child(0)
		label.size.x = label_width
	port_count = i
	_dirty = true
	
## when the visible field list changes for a model, the slot ids
## end up being shifted around.  This function will take the existing
## connections, disconnect them, and then remap them to the new slots by name
func refresh_fields():
	var conns = graph.get_connection_list_from_node(self.name)
	for c in conns:
		if c.to_node != self.name:
			continue
		var old_port = c.to_port
		c.slot_name = get_slot_name(get_input_slot_by_port(c.to_port))
		graph.disconnect_node(
			c.from_node, c.from_port,
			c.to_node, old_port
		)
		
	# debounce requests so that we only bother with updating slots once per frame
	_refresh = true
	await (Engine.get_main_loop() as SceneTree).process_frame
	if not _refresh:
		return
		
	var i = 0
	var n = 0
	ports.clear()
	slots.clear()
	for param in model.get_parameters():
		var hidden = model.get("modifiers/parameters/%s/hidden" % param)
		get_node(NodePath(param)).visible = not hidden
		if not hidden:
			ports[param.to_lower()] = i
			slots[i] = n
			i += 1
		n += 1
	port_count = i
		
	for c in conns:
		var new_port = get_input_port_by_name(c.slot_name)
		if new_port != -1:
			graph.connect_node(
				c.from_node, c.from_port,
				c.to_node, new_port
			)
	_refresh = false

func unbind(slot: int, node: GraphNode) -> void:
	var param = get_slot_name(get_input_slot_by_port(slot))
	bindings.erase(param)
	
func reset_value(slot: int) -> void:
	var param = get_slot_name(get_input_slot_by_port(slot))
	var default = model.property_get_revert("parameters/%s" % [param])
	bindings[param] = default
	_dirty = true
	
func get_input_slot_by_port(port: int) -> int:
	if port < 0 or port >= port_count:
		return -1
	return slots[port]
	
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
