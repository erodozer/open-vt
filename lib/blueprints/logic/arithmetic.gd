extends "../vt_action.gd"

enum Operator {
	Add,
	Multiply,
	Subtract,
	Divide,
	Modulo
}

var operator : Operator :
	get():
		return %Operator.selected
	set(v):
		%Operator.selected = v

var a : float :
	get():
		return %InputA.value
	set(v):
		%InputA.value = v

var b : float :
	get():
		return %InputB.value
	set(v):
		%InputB.value = v

func get_input_slot_by_port(port: int) -> int:
	match port:
		0:
			return 1
		1:
			return 2
		_:
			return -1

func get_input_port_by_name(slot: StringName) -> int:
	match slot.to_lower():
		"a":
			return 0
		"b":
			return 1
		_:
			return -1

func get_output_slot_by_port(port: int) -> int:
	match port:
		0:
			return 3
		_:
			return 0

func get_output_port_by_name(slot: StringName) -> int:
	match slot.to_lower():
		"value":
			return 0
		_:
			return -1

func get_type() -> StringName:
	return &"arithmetic"
	
func serialize():
	return {
		"operator": Operator.keys()[int(operator)],
		"a": null if not %InputA.editable else %InputA.value,
		"b": null if not %InputB.editable else %InputB.value
	}

func deserialize(data):
	var op = data.get("operator", "Add")
	if op in Operator:
		operator = Operator[op]
	else:
		operator = Operator.Add
	if data.get("a", null):
		a = data.get("a")
	if data.get("b", null):
		b = data.get("b")

func get_value(_slot):
	match operator:
		Operator.Add:
			return a + b
		Operator.Multiply:
			return a * b
		Operator.Subtract:
			return a - b
		Operator.Divide:
			return a / b
		Operator.Modulo:
			return fmod(a, b)
		_:
			return INF

func update_value(slot, value):
	var dirty = false
	if slot == %A.get_index() and a != value:
		a = value
		dirty = true
	elif slot == %B.get_index() and b != value:
		b = value
		dirty = true
		
	
	if dirty:
		slot_updated.emit(0)
	
func bind(slot: int, _node: GraphNode):
	if slot == 0:
		%InputA.editable = false
	if slot == 1:
		%InputB.editable = false

func unbind(slot: int, _node: GraphNode):
	if slot == 0:
		%InputA.editable = true
	if slot == 1:
		%InputB.editable = true
