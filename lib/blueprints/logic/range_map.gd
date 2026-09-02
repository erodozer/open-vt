extends "../vt_action.gd"

const a_slot = 0
const b_slot = 1
const v_slot = 2

var a : Vector2 :
	set(v):
		a = v
		%A/X.set_value_no_signal(v.x)
		%A/Y.set_value_no_signal(v.y)
		
var a_clamp : bool :
	set(v):
		a_clamp = v
		%A/Clamp.set_pressed_no_signal(v)

var b : Vector2 :
	set(v):
		b = v
		%B/X.set_value_no_signal(v.x)
		%B/Y.set_value_no_signal(v.y)
		
var b_clamp : bool :
	set(v):
		b_clamp = v
		%B/Clamp.set_pressed_no_signal(v)
		
var input_value : float :
	set(v):
		input_value = v
		%Value/In.text = "%1.2f" % v

func _ready() -> void:
	%A/X.value_changed.connect(
		func (v):
			a.x = v
	)
	%A/Y.value_changed.connect(
		func (v):
			a.y = v
	)
	%B/X.value_changed.connect(
		func (v):
			b.x = v
	)
	%B/Y.value_changed.connect(
		func (v):
			b.y = v
	)

func get_input_slot_by_port(port: int) -> int:
	match port:
		0:
			return a_slot
		1:
			return b_slot
		2:
			return v_slot
		_:
			return -1

func get_input_port_by_name(slot: StringName) -> int:
	match slot.to_lower():
		"a":
			return a_slot
		"b":
			return b_slot
		"value":
			return v_slot
		_:
			return -1

func get_output_slot_by_port(port: int) -> int:
	match port:
		0:
			return v_slot
		_:
			return -1

func get_output_port_by_name(slot: StringName) -> int:
	match slot.to_lower():
		"value":
			return 0
		_:
			return -1

func get_type() -> StringName:
	return &"rangemap"
	
func serialize():
	var a_is_bound = not %A/X.editable
	var b_is_bound = not %B/X.editable
	
	var output = {}
	if not a_is_bound:
		output["a"] = Serializers.Vec2Serializer.to_json(a)
	if not b_is_bound:
		output["b"] = Serializers.Vec2Serializer.to_json(b)
	
	return output

func deserialize(data):
	if data.get("a", null):
		a = Serializers.Vec2Serializer.from_json(data.a, Vector2.DOWN)
	if data.get("b", null):
		b = Serializers.Vec2Serializer.from_json(data.b, Vector2.DOWN)

func get_value(_slot):
	var input = clamp(input_value, a.x, a.y) if a_clamp else input_value
	var mapped = remap(
		input,
		a.x, a.y,
		b.x, b.y
	)
	var output = clamp(mapped, b.x, b.y) if b_clamp else mapped
	return output
	
func update_value(slot, value):
	var dirty = false
	if slot == a_slot and a != Vector2(value.x, value.y):
		a = Vector2(value.x, value.y)
		dirty = true
	elif slot == b_slot and b != Vector2(value.x, value.y):
		b = Vector2(value.x, value.y)
		dirty = true
	elif slot == v_slot and input_value != value:
		input_value = value
		dirty = true
		
	if dirty:
		%Value/Out.text = "%1.2f" % get_value(0)
		slot_updated.emit(0)
	
func bind(slot: int, _node: GraphNode):
	if slot == 0:
		%A/X.editable = false
		%A/Y.editable = false
	if slot == 1:
		%B/X.editable = false
		%B/Y.editable = false

func unbind(slot: int, _node: GraphNode):
	if slot == 0:
		%A/X.editable = true
		%A/Y.editable = true
	if slot == 1:
		%B/X.editable = true
		%B/Y.editable = true
	
