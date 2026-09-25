extends "../vt_action.gd"

var ports: Dictionary[String, int] = {}
var slots: Dictionary[int, int] = {}
var port_count = 0
var bindings = {}
var binding_display = {}
var _dirty = false
var _refresh = false

## only allow one model output per graph
func can_spawn(graph: GraphEdit) -> bool:
	return not graph.find_children("*", "VtAction", false).any(
		func (n):
			return n.get_type() == self.get_type()
	)
	
# Called when the node enters the scene tree for the first time.
func set_model(m: VtModel):
	if model == m:
		return
	assert(model == null, "model has already be initialized")
	model = m
	
	model.modifier_updated.connect(
		func (field: StringName, _new, _old):
			if field.begins_with("parameters"):
				_refresh = true
	)
	
func _build_slots():
	for prop in get_children():
		remove_child(prop)
		prop.queue_free()

	var i = 0
	var label_width = 0
	var parameters = model.get_parameters()
	binding_display.clear()
	for property in parameters:
		var meta = parameters[property]
		var vis = model.get("modifiers/parameters/%s/visible" % property)
		if vis != null and vis == false:
			continue
		var value_range: Vector2 = meta.range
		
		var box = HBoxContainer.new()
		box.name = property
		
		var l = Label.new()
		l.text = property
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.size_flags_stretch_ratio = 2.0
		l.tooltip_text = "[%1.2f, %1.2f]" % [
			value_range.x, value_range.y
		]
		l.mouse_filter = Control.MOUSE_FILTER_PASS
		
		label_width = max(
			l.get_theme_default_font().get_string_size(property).x,
			l.size.x
		)
		l.custom_minimum_size = Vector2(label_width + 20, 24)
		box.add_child(l)
		
		var current_value = LineEdit.new()
		current_value.editable = false
		current_value.alignment = HORIZONTAL_ALIGNMENT_RIGHT
		box.add_child(current_value)
		
		add_child(box)
		
		binding_display[property] = current_value
					
		var slot = get_child_count()-1
		set_slot_enabled_left(slot, true)
		set_slot_type_left(slot, SlotType.NUMERIC)
		ports[property.to_lower()] = i
		slots[i] = slot
		
		# do initial reset of all parameters
		# will be cleared after first update
		bindings[property] = meta.default
		i += 1
			
	# readjust sizes for columns to match
	for row in get_children():
		var label = row.get_child(0)
		label.size.x = label_width
	port_count = i
	_dirty = true
	size.y = 0
	
func unbind(slot: int, node: GraphNode) -> void:
	var param = get_input_slot_name(get_input_slot_by_port(slot))
	bindings.erase(param)
	
func reset_value(slot: int) -> void:
	var param = get_input_slot_name(get_input_slot_by_port(slot))
	var default = model.property_get_revert("parameters/%s" % [param])
	bindings[param] = default
	_dirty = true
	
func get_input_slot_by_port(port: int) -> int:
	if port < 0 or port >= get_child_count():
		return -1
	return port
	
func get_input_port_by_name(slot: StringName) -> int:
	var node = get_node(NodePath(slot))
	if node:
		return node.get_index()
	return -1

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
	var parameter: StringName = get_input_slot_name(slot)
	bindings[parameter] = type_convert(v, TYPE_FLOAT)
	_dirty = true
	
func _update_model():
	if not _dirty:
		return
	
	if model.is_queued_for_deletion():
		return
	
	for p in bindings:
		model.set("parameters/%s" % [p], bindings[p])
	_dirty = false
	bindings.clear()
	
func _process(_delta: float) -> void:
	if not graph.enabled:
		return
	
	if _refresh:
		build_slots()
		_refresh = false
		return
	
	_update_model()
	for param in model.get_parameters().keys():
		if param in binding_display:
			var value = model.get("parameters/%s" % [param])
			if value == null:
				value = 0.0
			binding_display[param].text = "%1.2f" % value
