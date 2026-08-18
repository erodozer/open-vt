extends "../vt_action.gd"

enum Operator {
	Add,
	Multiply,
	Subtract,
	Divide,
	Modulo,
	Clamp,
	Lerp,
	InvLerp
}

const VECTOR_OPERATORS: Array[Operator] = [
	Operator.Clamp,
	Operator.Lerp,
	Operator.InvLerp
]

var operator: Operator = Operator.Add :
	set(v):
		self.title = (Operator.keys()[v] as String).capitalize()
		
		%A/Value.visible = v not in VECTOR_OPERATORS
		%A/X.visible = v in VECTOR_OPERATORS
		%A/Y.visible = v in VECTOR_OPERATORS
		
		self.set_slot_type_left(0, VtAction.SlotType.VECTOR if v in VECTOR_OPERATORS else VtAction.SlotType.NUMERIC)
		
		operator = v
		
var a : float :
	get():
		return %A/Value.value
	set(v):
		%A/Value.value = v

var input_range: Vector2 :
	get():
		return Vector2(
			%A/X.value,
			%A/Y.value,
		)
	set(v):
		input_range = v
		%A/X.value = v.x
		%A/Y.value = v.y

var b : float :
	get():
		return %B/Value.value
	set(v):
		%B/Value.value = v

func get_input_slot_by_port(port: int) -> int:
	match port:
		0:
			return 0
		1:
			return 1
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
			return 2
		_:
			return -1

func get_output_port_by_name(slot: StringName) -> int:
	match slot.to_lower():
		"value":
			return 0
		_:
			return -1

func get_type() -> StringName:
	return &"arithmetic"
	
func serialize():
	var a_is_bound = not %A/Value.editable
	var a_is_vector = operator in VECTOR_OPERATORS
	var b_is_bound = not %B/Value.editable
	
	var output = {
		"operator": (Operator.keys()[operator] as String)
	}
	if not a_is_bound:
		if a_is_vector:
			output["a"] = Serializers.Vec2Serializer.to_json(input_range)
		else:
			output["a"] = a
	if not b_is_bound:
		output["b"] = b
	
	return output

func deserialize(data):
	operator = data.get("operator", Operator.Add)
	if data.get("a", null):
		if data.a is Dictionary:
			a = Serializers.Vec2Serializer.from_json(data.a, Vector2.DOWN)
		elif data.a is float:
			a = data.a
	if data.get("b", null):
		b = data.get("b") as float

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
		Operator.Clamp:
			return clamp(b, input_range.x, input_range.y)
		Operator.Lerp:
			return lerp(input_range.x, input_range.y, b)
		Operator.InvLerp:
			return inverse_lerp(input_range.x, input_range.y, b)
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
		%Output/Display.text = "%1.2f" % get_value(0)
		slot_updated.emit(0)
	
func bind(slot: int, _node: GraphNode):
	if slot == 0:
		%A/Value.editable = false
		%A/X.editable = false
		%A/Y.editable = false
	if slot == 1:
		%B/Value.editable = false

func unbind(slot: int, _node: GraphNode):
	if slot == 0:
		%A/Value.editable = true
		%A/X.editable = true
		%A/Y.editable = true
	if slot == 1:
		%B/Value.editable = true
