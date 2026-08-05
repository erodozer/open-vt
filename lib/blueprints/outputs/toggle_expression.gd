extends "../vt_action.gd"

@onready var input: OptionButton = %Expression

var expression: String = "" :
	set(e):
		expression = e
		if input:
			var expressions = model.get_expression_controller().expressions
			var idx = expressions.find_custom(func (x): return x.get_name() == e) + 1
			input.select(idx)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var controller = model.get_expression_controller()
	var expressions = model.get_expression_controller().expressions
	for m in expressions:
		var name = m.get_name()
		input.add_item(name)
		input.set_item_metadata(input.item_count - 1, m)
		var active = controller.is_activated(name)
		%Active.button_pressed = active
		if expression == name:
			input.selected = input.item_count - 1

func get_type() -> StringName:
	return &"expression"
	
func serialize():
	return {
		"name": self.expression,
	}
	
func deserialize(data: Dictionary):
	self.expression = data.get("name")

func get_input_slot_by_port(port: int) -> int:
	match port:
		0:
			return 1
		1:
			return 2
		2:
			return 3
		_:
			return -1

func get_input_port_by_name(slot: StringName) -> int:
	match slot.to_lower():
		"toggle":
			return 0
		"on":
			return 1
		"off":
			return 2
		_:
			return -1

func get_output_slot_by_port(port: int) -> int:
	return -1

func get_output_port_by_name(slot: StringName) -> int:
	return -1

func invoke_trigger(slot: int) -> void:
	var activate: bool
	if expression.is_empty():
		activate = false
	elif slot == 1:
		activate = not model.get_expression_controller().is_activated(StringName(expression))
	elif slot == 2:
		activate = true
	elif slot == 3:
		activate = false
		
	model.toggle_expression(
		expression,
		activate,
		%Fade/Value.value / 1000.0
	)
	%Active.button_pressed = activate

func _on_expression_item_selected(_index: int) -> void:
	expression = input.get_selected_metadata()
	if expression == null:
		expression = ""
