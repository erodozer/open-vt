extends VtAction

const flip_slot = 0
const on_slot = 1
const off_slot = 2

var state : bool :
	set(v):
		state = v
		%Input.set_pressed_no_signal(state)

func get_input_slot_by_port(port: int) -> int:
	match port:
		0:
			return flip_slot
		1:
			return on_slot
		2:
			return off_slot
		_:
			return -1

func get_input_port_by_name(slot: StringName) -> int:
	match slot.to_lower():
		"flip":
			return 0
		"on":
			return 1
		"off":
			return 2
		_:
			return -1

func get_output_slot_by_port(port: int) -> int:
	match port:
		0:
			return on_slot
		1:
			return off_slot
		_:
			return -1

func get_output_port_by_name(slot: StringName) -> int:
	match slot.to_lower():
		"on":
			return 0
		"off":
			return 1
		_:
			return -1

func get_type() -> StringName:
	return &"toggle_state"
	
func serialize():
	return {
		"toggled": state
	}

func deserialize(data):
	state = data.get("toggled", false)

func get_value(_slot):
	return state
	
func invoke_trigger(slot: int):
	match slot:
		0:
			update_value(0, not state)
		1:
			update_value(0, true)
		2:
			update_value(0, false)
	
func update_value(slot, value):
	var dirty = false
	if state != value:
		dirty = true
		state = value
		
	if dirty:
		if state:
			slot_updated.emit(0)
		else:
			slot_updated.emit(1)
	
func get_input_slot_name(slot: int) -> StringName:
	match slot:
		flip_slot:
			return "flip"
		on_slot:
			return "on"
		off_slot:
			return "off"
		_:
			return ""

func get_output_slot_name(slot: int) -> StringName:
	match slot:
		on_slot:
			return "on"
		off_slot:
			return "off"
		_:
			return ""
	
func bind(slot: int, _node: GraphNode):
	pass
	
func unbind(slot: int, _node: GraphNode):
	pass
