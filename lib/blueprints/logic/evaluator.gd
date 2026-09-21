extends VtAction

var inputs = {}
var expression: Expression
var value: float = 0.0 :
	set(v):
		value = v
		%Output.text = "%.2f" % [v]

func _ready() -> void:
	%Formula.editing_toggled.connect(
		func (toggled_on):
			if not toggled_on:
				build_slots()
	)

func _build_slots():
	var formula = %Formula.text
	expression = Expression.new()
	# extract any variables
	var regex = RegEx.create_from_string(r"(?<variable>\$[a-zA-Z_]+)")
	var found = {}
	for m in regex.search_all(formula):
		var input_name = m.get_string("variable")
		found[input_name.substr(1)] = 0.0
	
	var error = expression.parse(formula.replace("$", ""), found.keys())
	if error != OK:
		return
		
	if found.keys() == inputs.keys():
		return
	inputs = found
		
	var total = get_child_count()
	var current_count = total - 1 # don't count formula slot
	var count = len(inputs.keys())
	
	while get_child_count() > 1:
		var slot = get_child(1)
		remove_child(slot)
		slot.queue_free()
		
	for i in range(count):
		var name = inputs.keys()[i]
		
		var slot = HBoxContainer.new()
		slot.name = name
		add_child(slot)
		
		var label = Label.new()
		label.text = name
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.add_child(label)
		
		var display = LineEdit.new()
		display.alignment = HORIZONTAL_ALIGNMENT_RIGHT
		display.text = "0.0"
		display.name = "Value"
		display.editable = false
		display.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.add_child(display)
		
		set_slot_enabled_left(i + 1, true)
		set_slot_type_left(i + 1, VtAction.SlotType.NUMERIC)
	size.y = 0

func get_input_slot_by_port(port: int) -> int:
	if port >= 0:
		return port + 1
	return -1

func get_input_port_by_name(slot: StringName) -> int:
	return inputs.keys().find(String(slot))

func get_output_slot_by_port(port: int) -> int:
	if port == 0:
		return port
	return -1

func get_output_port_by_name(slot: StringName) -> int:
	if slot.to_lower() == "value":
		return 0
	return -1

func get_type() -> StringName:
	return &"evaluator"
	
func serialize():
	return {
		"formula": %Formula.text
	}

func deserialize(data):
	var formula = data.get("formula", "")
	%Formula.text = formula
	build_slots()

func get_value(slot):
	return value

func update_value(slot: int, value: Variant) -> void:
	var dirty = false
	var input = inputs.keys().get(slot - 1)
	if not input:
		return
	if not has_node(input):
		return
	inputs[input] = value
	get_node(input).get_node("Value").text = "%.2f" % [value]
	
	var result = expression.execute(inputs.values())
	if expression.has_execute_failed() or result == null:
		return
	if result != self.value:
		self.value = result
		slot_updated.emit(0)

func get_input_slot_name(slot: int) -> StringName:
	var name = inputs.keys().get(slot)
	if name == null:
		name = ""
	return name

func get_output_slot_name(slot: int) -> StringName:
	if slot == 0:
		return "value"
	return ""
