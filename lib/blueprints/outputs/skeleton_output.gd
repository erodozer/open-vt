extends VtAction

# Called when the node enters the scene tree for the first time.
func set_model(m: VtModel):
	if model == m:
		return
	model = m
	assert(m.is_3D, "model should be 3D with a skeleton")
	
func get_type() -> StringName:
	return &"skeleton"
	
func serialize():
	return {}
	
func deserialize(data: Dictionary):
	pass
	
func _build_slots() -> void:
	for i in get_children():
		remove_child(i)
		i.queue_free()
		
	for i in range(model.skeleton.get_bone_count()):
		var label = Label.new()
		label.text = model.skeleton.get_bone_name(i)
		label.name = model.skeleton.get_bone_name(i)
		add_child(label)
		set_slot_enabled_left(i, true)
		set_slot_type_left(i, VtAction.SlotType.VECTOR)

func get_input_slot_by_port(port: int) -> int:
	return clamp(port, -1, get_child_count())
	
func get_input_port_by_name(slot: StringName) -> int:
	if has_node(NodePath(slot)):
		return get_node(NodePath(slot)).get_index()
	return -1

func get_output_slot_by_port(port: int) -> int:
	return -1

func get_output_port_by_name(slot: StringName) -> int:
	return -1
	
func update_value(slot: int, value: Variant) -> void:
	if value == null:
		return
	
	var parent_transform = model.skeleton.get_bone_global_pose(
		model.skeleton.get_bone_parent(slot)
	).inverse()
	var rest_transform = model.skeleton.get_bone_rest(slot)
	
	var t = rest_transform * value
	
	model.skeleton.set_bone_pose(slot, t)
