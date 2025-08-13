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

func get_type() -> StringName:
	return "arithmetic"
	
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

func update_value(slot, value):
	var dirty = false
	if slot == 0 and a != value:
		a = value
		dirty = true
	if slot == 1 and b != value:
		b = value
		dirty = true
	
	if dirty:
		slot_updated.emit(0)
	
func bind(slot: int, node: GraphNode):
	if slot == 0:
		%InputA.editable = false
	if slot == 1:
		%InputB.editable = false

func unbind(slot: int, node: GraphNode):
	if slot == 0:
		%InputA.editable = true
	if slot == 1:
		%InputB.editable = true
