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
	return &"compose"

func _build_slots() -> void:
	for i in get_children():
		remove_child(i)
		i.queue_free()
		
	var components: Dictionary[String, VtAction.SlotType] = {}
	var output: Dictionary[String, VtAction.SlotType] = {}
	match kind:
		Kind.Vector:
			components = {
				"x": VtAction.SlotType.NUMERIC,
				"y": VtAction.SlotType.NUMERIC,
				"z": VtAction.SlotType.NUMERIC,
			}
			output = {
				"vector": VtAction.SlotType.VECTOR
			}
			composed_value = Vector3.ZERO
		Kind.Transform:
			components = {
				"position": VtAction.SlotType.VECTOR,
				"rotation": VtAction.SlotType.VECTOR,
			}
			output = {
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
	
func get_output_port_by_name(slot: StringName) -> int:
	match kind:
		Kind.Vector:
			if slot.to_lower() == "vector":
				return 0
		Kind.Transform:
			if slot.to_lower() == "transform":
				return 0
	return -1

func get_input_slot_by_port(port: int) -> int:
	if port < 0:
		return -1
	if kind == Kind.Vector and port < 3:
		return port
	elif kind == Kind.Transform and port < 2:
		return port
	return -1
	
func get_output_slot_by_port(port: int) -> int:
	if port != 0:
		return -1
	match kind:
		Kind.Vector:
			return 3
		Kind.Transform:
			return 2
	return -1

func get_value(slot: int) -> Variant:
	return composed_value
	
func update_value(slot: int, value: Variant) -> void:
	match kind:
		Kind.Vector:
			if typeof(value) != TYPE_FLOAT:
				return
			match slot:
				0:
					composed_value.x = value
				1:
					composed_value.y = value
				2:
					composed_value.z = value
		Kind.Transform:
			if typeof(value) != TYPE_VECTOR3:
				return
			match slot:
				0: # position
					composed_value = Transform3D(
						composed_value.basis,
						value
					)
				1: # rotation
					composed_value = Transform3D(
						Basis.from_euler(Vector3(
							deg_to_rad(value.x),
							deg_to_rad(value.y),
							deg_to_rad(value.z),
						)),
						composed_value.origin
					)
	slot_updated.emit(0)
