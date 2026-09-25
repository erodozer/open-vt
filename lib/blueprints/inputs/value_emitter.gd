extends VtAction

enum Kind {
	Numeric,
	Vector,
	Transform
}

var kind: Kind = Kind.Numeric
var value: Variant :
	set(v):
		value = v
		slot_updated.emit(0)
var is_bound: bool = false

func get_type() -> StringName:
	return "value_emitter"

func _build_slots() -> void:
	var control
	match kind:
		Kind.Numeric:
			control = SpinBox.new()
			control.value_changed.connect(
				func (v):
					value = v
			)
			control.min_value = -1000
			control.max_value = 1000
			control.step = 0.01
			control.name = "Value"
			
			set_slot_type_left(0, VtAction.SlotType.NUMERIC)
			set_slot_type_right(0, VtAction.SlotType.NUMERIC)
		Kind.Vector:
			control = HBoxContainer.new()
			value = Vector3.ZERO
			for component in ["X", "Y", "Z"]:
				var part = SpinBox.new()
				part.name = component
				part.suffix = component
				part.min_value = -1000
				part.max_value = 1000
				part.step = 0.01
				part.value_changed.connect(
					func (v):
						value = Vector3(
							control.get_node("X").value,
							control.get_node("Y").value,
							control.get_node("Z").value
						)
				)
				control.add_child(part, true)
			
			set_slot_type_left(0, VtAction.SlotType.VECTOR)
			set_slot_type_right(0, VtAction.SlotType.VECTOR)
		Kind.Transform:
			control = VBoxContainer.new()
			var label = Label.new()
			label.text = "Transform"
			control.add_child(label)
			
			value = Transform3D.IDENTITY
			var position_field = HBoxContainer.new()
			position_field.name = "Position"
			label = Label.new()
			label.text = "Position"
			label.theme_type_variation = "FieldLabel"
			position_field.add_child(label)
			for component in ["X", "Y", "Z"]:
				var part = SpinBox.new()
				part.name = component
				part.suffix = component
				part.alignment = HORIZONTAL_ALIGNMENT_RIGHT
				part.min_value = -10
				part.max_value = 10
				part.step = 0.01
				part.value_changed.connect(
					func (_v):
						var origin = Vector3(
							position_field.get_node("X").value,
							position_field.get_node("Y").value,
							position_field.get_node("Z").value
						)
						value = Transform3D(
							value.basis,
							origin
						)
				)
				position_field.add_child(part)
			
			var rotation_field = HBoxContainer.new()
			rotation_field.name = "Rotation"
			label = Label.new()
			label.text = "Rotation"
			label.theme_type_variation = "FieldLabel"
			rotation_field.add_child(label)
			for component in ["X", "Y", "Z"]:
				var part = SpinBox.new()
				part.name = component
				part.suffix = component
				part.min_value = -360
				part.max_value = 360
				part.alignment = HORIZONTAL_ALIGNMENT_RIGHT
				part.value_changed.connect(
					func (_v):
						var euler = Vector3(
							deg_to_rad(rotation_field.get_node("X").value),
							deg_to_rad(rotation_field.get_node("Y").value),
							deg_to_rad(rotation_field.get_node("Z").value),
						)
						value = Transform3D(
							Basis.from_euler(euler),
							value.origin
						)
				)
				rotation_field.add_child(part)
			control.add_child(position_field)
			control.add_child(rotation_field)
	
			set_slot_type_left(0, VtAction.SlotType.TRANSFORM)
			set_slot_type_right(0, VtAction.SlotType.TRANSFORM)
	if not control:
		return
	
	var old = get_node("Value")
	remove_child(old)
	old.queue_free()
	control.name = "Value"
	add_child(control)
	move_child(control, 0)

func get_input_port_by_name(slot: StringName) -> int:
	match slot.to_lower():
		"value":
			return 0
		"trigger":
			return 1
		_:
			return -1

func get_output_port_by_name(slot: StringName) -> int:
	match slot.to_lower():
		"value":
			return 0
		_:
			return -1

func get_input_slot_by_port(port: int) -> int:
	if port == 0:
		return 0
	if port == 1:
		return 1
	return -1

func get_output_slot_by_port(port: int) -> int:
	if port == 0:
		return 0
	return -1

func invoke_trigger(slot: int):
	match slot:
		1:
			slot_updated.emit(0)

func update_value(slot: int, input: Variant) -> void:
	if slot != 0:
		return
		
	match kind:
		Kind.Numeric:
			if typeof(input) != TYPE_FLOAT:
				return
			value = input
			$Value.set_value_no_signal(input)
		Kind.Vector:
			if typeof(input) != TYPE_VECTOR3:
				return
			value = input
			$Value/X.set_value_no_signal(input.x)
			$Value/Y.set_value_no_signal(input.y)
			$Value/Z.set_value_no_signal(input.z)
		Kind.Transform:
			if typeof(input) != TYPE_TRANSFORM3D:
				return
			value = input
			$Value/Position/X.set_value_no_signal(input.origin.x)
			$Value/Position/Y.set_value_no_signal(input.origin.y)
			$Value/Position/Z.set_value_no_signal(input.origin.z)
			var euler = input.basis.get_euler()
			$Value/Rotation/X.set_value_no_signal(rad_to_deg(euler.x))
			$Value/Rotation/Y.set_value_no_signal(rad_to_deg(euler.y))
			$Value/Rotation/Z.set_value_no_signal(rad_to_deg(euler.z))
	
func get_value(slot: int) -> Variant:
	if slot == 0:
		return value
	return null

func serialize():
	var out = {}
	out["kind"] = Kind.keys()[kind]
	match kind:
		Kind.Numeric:
			out["value"] = type_convert(value, TYPE_FLOAT)
		Kind.Vector:
			out["value"] = Serializers.Vec3Serializer.to_json(value)
		Kind.Transform:
			out["value"] = Serializers.TransformSerializer.to_json(value)
	return out
	
func deserialize(data):
	kind = Kind.get(data.get("kind", "Numeric"), Kind.Numeric)
	var v = null
	match kind:
		Kind.Numeric:
			v = type_convert(data.value, TYPE_FLOAT)
		Kind.Vector:
			v = Serializers.Vec3Serializer.from_json(data.value)
		Kind.Transform:
			v = Serializers.TransformSerializer.from_json(data.value)
	if v != null:
		update_value.call_deferred(0, v)

func bind(slot: int, node: GraphNode) -> void:
	if slot == 0:
		is_bound = true
		
func unbind(slot: int, node: GraphNode) -> void:
	if slot == 0:
		is_bound = false
