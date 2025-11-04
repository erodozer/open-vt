extends "../vt_action.gd"

@onready var input: OptionButton = %Expression

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var expressions = stage.active_model.expressions
	for m in expressions:
		input.add_item(m)
		input.set_item_metadata(input.item_count - 1, m)
		%Toggle/CheckButton.button_pressed = stage.active_model.expression_controller.is_activated(m)

func get_type():
	return "expression"
	
func serialize():
	return {
		"name": input.get_item_text(input.selected),
	}
	
func deserialize(data: Dictionary):
	for i in input.item_count:
		if input.get_item_text(i) == data.get("name"):
			input.select(i)

func invoke_trigger(slot: int) -> void:
	var activate: bool
	var expression = input.get_selected_metadata()
	if expression == null:
		expression = ""
		activate = false
	elif slot == 1:
		activate = not stage.active_model.expression_controller.is_activated(input.get_selected_metadata())
	elif slot == 2:
		activate = true
	elif slot == 3:
		activate = false
		
	stage.active_model.toggle_expression(
		expression,
		activate,
		%Fade/Value.value / 1000.0
	)
	%Toggle/CheckButton.button_pressed = activate
