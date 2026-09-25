extends VtAction

enum Kind {
	Vector,
	Transform
}

var kind: Kind :
	set(v):
		kind = v
		
var composed_value: Variant

func get_type() -> StringName:
	return &"decompose"

func _build_slots() -> void:
	for i in get_children():
		remove_child(i)
		i.queue_free()
		
	var components: Dictionary[String, VtAction.SlotType] = {}
	var output: Dictionary[String, VtAction.SlotType] = {}
	match kind:
		Kind.Vector:
			output = {
				"x": VtAction.SlotType.NUMERIC,
				"y": VtAction.SlotType.NUMERIC,
				"z": VtAction.SlotType.NUMERIC,
			}
			components = {
				"vector": VtAction.SlotType.VECTOR
			}
			composed_value = Vector3.ZERO
		Kind.Transform:
			output = {
				"position": VtAction.SlotType.VECTOR,
				"rotation": VtAction.SlotType.VECTOR,
			}
			components = {
				"transform": VtAction.SlotType.TRANSFORM
			}
			composed_value = Transform3D.IDENTITY
	
	var idx = 0
	for i in components:
		var label = Label.new()
		label.text = i.capitalize()
		label.name = i
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		add_child(label)
		set_slot_enabled_left(idx, true)
		set_slot_enabled_right(idx, false)
		set_slot_type_left(idx, components[i])
		idx += 1
		
	for i in output:
		var label = Label.new()
		label.text = i.capitalize()
		label.name = i
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		add_child(label)
		set_slot_enabled_left(idx, false)
		set_slot_enabled_right(idx, true)
		set_slot_type_right(idx, output[i])
		idx += 1

func serialize() -> Dictionary:
	return {
		"kind": Kind.keys()[kind]
	}
	
func deserialize(data: Dictionary) -> void:
	self.kind = Kind.get(data.get("kind", "Vector"), Kind.Vector)

func get_input_port_by_name(slot: StringName) -> int:
	match kind:
		Kind.Vector:
			if slot.to_lower() == "vector":
				return 0
		Kind.Transform:
			if slot.to_lower() == "transform":
				return 0
	return -1
	
func get_output_port_by_name(slot: StringName) -> int:
	match kind:
		Kind.Vector:
			match slot.to_lower():
				"x":
					return 0
				"y":
					return 1
				"z":
					return 2
		Kind.Transform:
			match slot.to_lower():
				"position":
					return 0
				"rotation":
					return 1
	return -1

func get_input_slot_by_port(port: int) -> int:
	if port != 0:
		return -1
	return 0
	
func get_output_slot_by_port(port: int) -> int:
	if port >= 0:
		if kind == Kind.Vector and port < 3:
			return port + 1
		if kind == Kind.Transform and port < 2:
			return port + 1
	return -1

func get_value(slot: int) -> Variant:
	match kind:
		Kind.Vector:
			match slot:
				1:
					return composed_value.x
				2:
					return composed_value.y
				3:
					return composed_value.z
		Kind.Transform:
			match slot:
				1: # position
					return composed_value.origin
				2: # rotation
					var euler = composed_value.basis.get_euler()
					return Vector3(
						rad_to_deg(euler.x),
						rad_to_deg(euler.y),
						rad_to_deg(euler.z),
					)
	return null
		
func update_value(slot: int, value: Variant) -> void:
	if slot != 0:
		return
	
	match kind:
		Kind.Vector:
			if typeof(value) != TYPE_VECTOR3:
				return
			composed_value = value
		Kind.Transform:
			if typeof(value) != TYPE_TRANSFORM3D:
				return
			composed_value = value
			
	for i in get_output_port_count():
		slot_updated.emit(i)
