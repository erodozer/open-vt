extends "../vt_action.gd"

@onready var input: OptionButton = %Expression

var expression: String = "" :
	set(e):
		expression = e
		if input:
			var expressions = model.expression_controller.expression_library.keys()
			var idx = expressions.find(e) + 1
			input.select(idx)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var expressions = model.expressions
	for m in expressions:
		input.add_item(m)
		input.set_item_metadata(input.item_count - 1, m)
		%Active.button_pressed = model.expression_controller.is_activated(m)
		if expression == m:
			input.selected = input.item_count - 1

func get_type() -> StringName:
	return &"expression"
	
func serialize():
	return {
		"name": input.get_selected_metadata(),
	}
	
func deserialize(data: Dictionary):
	for i in input.item_count:
		if input.get_item_text(i) == data.get("name"):
			input.select(i)

func invoke_trigger(slot: int) -> void:
	var activate: bool
	if expression.is_empty():
		activate = false
	elif slot == 0:
		activate = not model.expression_controller.is_activated(StringName(expression))
	elif slot == 1:
		activate = true
	elif slot == 2:
		activate = false
		
	model.toggle_expression(
		expression,
		activate,
		%Fade/Value.value / 1000.0,
		%Exclusive.button_pressed
	)
	%Active.button_pressed = activate

func _on_expression_item_selected(_index: int) -> void:
	expression = input.get_selected_metadata()
	if expression == null:
		expression = ""
