extends "../vt_action.gd"

const Collections = preload("res://lib/utils/collections.gd")

var input: OptionButton:
	get():
		return %Expression

var expression: String:
	set(v):
		var controller = model.get_expression_controller()
		var idx = (controller.expressions as Array).find_custom(
			func (e):
				return e.get_name() == v
		)
		if idx == -1:
			expression = ""
		else:
			expression = v
			var active = controller.is_activated(expression)
			%Active.button_pressed = active
		self.input.select(idx + 1)
		
# Called when the node enters the scene tree for the first time.
func set_model(m: VtModel):
	if model == m:
		return
	model = m
	var controller = m.get_expression_controller()
	var expressions = controller.expressions
	for e in expressions:
		var name = e.get_name()
		var group = controller.get("expression_groups/%s" % name)
		if group:
			input.add_item("%s/%s" % [group, name])
		else:
			input.add_item(name)
		input.set_item_metadata(input.item_count - 1, m)
		
func get_type() -> StringName:
	return &"expression"
	
func serialize():
	var out = {}
	if self.expression:
		out["name"] = self.expression
	return out
	
func deserialize(data: Dictionary):
	if data.get("name"):
		self.expression = data.name

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
		
	var fade = %Fade/Value.value / 1000.0
	var controller: AyagamiExpressionMutator = model.get_expression_controller()
	var groups:Array = controller.get("expression_groups/%s" % expression)
	var tween = create_tween().set_parallel(true)
	if not groups.is_empty() and activate:
		for e in controller.expressions:
			var e_name = e.get_name()
			if e_name == expression:
				continue
				
			var e_groups: Array = controller.get("expression_groups/%s" % e_name)
			if not Collections.intersect(groups, e_groups).is_empty():
				tween.tween_property(controller, "weight/%s" % e_name, 0.0, fade)
		tween.tween_property(controller, "weight/%s" % expression, 1.0, fade)
	elif activate:
		tween.tween_property(controller, "weight/%s" % expression, 1.0, fade)
	else:
		tween.tween_property(controller, "weight/%s" % expression, 0.0, fade)

	%Active.button_pressed = activate

func _on_expression_item_selected(_index: int) -> void:
	expression = input.get_selected_metadata()
	if expression == null:
		expression = ""
