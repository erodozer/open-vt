extends "../vt_action.gd"

const TrackingSystem = preload("res://lib/tracking/tracking_system.gd")
	
var inputs = []
var _rebuild = false
var _dirty = false
	
func _ready() -> void:
	model.store_changed.connect(build_slots)
	
func _values_changed(_slot):
	_dirty = true

func get_type() -> StringName:
	return &"store_read"
	
func serialize():
	return {}
	
func deserialize(data):
	pass
	
# push current state of data store every frame
func _process(delta: float) -> void:
	for i in range(get_child_count()):
		slot_updated.emit(i)
	
func _build_slots():
	for prop in get_children():
		remove_child(prop)
		prop.queue_free()
	
	# values might not have been written to the model yet, so the keys wouldn't be in its store obj
	# instead we look for all writers to know what possible keys to bind to exist
	inputs = get_tree().get_nodes_in_group("blueprint:store:write").reduce(
		func (acc, writer):
			if writer.model == model and writer.var_name not in acc:
				acc.append(writer.var_name)
			return acc,
		[]
	)
	inputs.sort()
	
	for i in range(len(inputs)):
		var prop = inputs[i]
		var label = Label.new()
		label.text = prop
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.name = prop
		add_child(label)
		set_slot_enabled_right(i, true)
		set_slot_type_right(i, VtAction.SlotType.NUMERIC)
	
	size = Vector2.ZERO
	
func get_input_slot_by_port(_port: int) -> int:
	return -1

func get_input_port_by_name(_slot: StringName) -> int:
	return -1

func get_output_slot_by_port(port: int) -> int:
	if port < 0 or port >= get_child_count():
		return -1
	return port

func get_output_port_by_name(slot: StringName) -> int:
	return inputs.find(slot)
	
func get_output_slot_name(slot: int) -> StringName:
	return inputs.get(slot)
	
func get_value(slot: int):
	var name = get_output_slot_name(slot)
	var value = model.get("store/%s" % name)
	return value
