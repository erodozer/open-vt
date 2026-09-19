extends VtAction

var value: float

func get_type() -> StringName:
	return "value_emitter"

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
		
	self.value = input
	%Value.set_value_no_signal(input)
	slot_updated.emit(0)
	
func get_value(slot: int) -> Variant:
	if slot == 0:
		return value
	return null

func _on_value_changed(value: float) -> void:
	update_value(0, value)

func serialize():
	return {
		"value": value
	}
	
func deserialize(data):
	update_value(0, data.get("value", 0.0))

func bind(slot: int, node: GraphNode) -> void:
	if slot == 0:
		%Value.editable = false
		
func unbind(slot: int, node: GraphNode) -> void:
	if slot == 0:
		%Value.editable = true
