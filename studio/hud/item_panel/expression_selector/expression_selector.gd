extends Window

const VtModel = preload("res://lib/model/vt_model.gd")
const Collections = preload("res://lib/utils/collections.gd")

var item: VtModel
var buttons: Dictionary[AyagamiExpression, Array] = {}

@onready var exp_controller: AyagamiExpressionMutator = item.get_expression_controller()
@onready var expressions = exp_controller.expressions.duplicate()
func _ready():
	expressions.sort_custom(
		func (e, _e):
			return exp_controller.get("expression_groups/%s" % e.get_name()).is_empty()
	)
	var groups = [""] + exp_controller.get_expression_groups()
	var group_controls = {}
	var sections = {
		"": VBoxContainer.new()
	}
	for group in groups:
		sections[group] = VBoxContainer.new()
		group_controls[group] = ButtonGroup.new()
		group_controls[group].allow_unpress = true
		
	for e in expressions:
		var e_name = e.get_name()
		var e_groups = exp_controller.get("expression_groups/%s" % e_name)
		var btns: Array = buttons.get(e, [])
		for group in e_groups:
			var section = sections[group]
			var btn_group = group_controls[group]
			var row = make_row(e, btn_group)
			
			var btn = row.get_node("Toggle")
			btns.append(btn)
			
			section.add_child(row)
		if e_groups.is_empty():
			var row = make_row(e)
			var btn = row.get_node("Toggle")
			btns.append(btn)
			
			sections[""].add_child(row)
		
		buttons[e] = btns
		for b in btns:
			b.set_pressed_no_signal(exp_controller.get("expressions/%s" % e_name))
			
	for group in sections:
		var section: Node = sections[group]
		if section.get_child_count() <= 0:
			continue
			
		if not group.is_empty():
			var l = Label.new()
			l.text = group
			l.theme_type_variation = "BoldLabel"
			%ExpressionList.add_child(l)
		%ExpressionList.add_child(section)
	
	await get_tree().process_frame
	
	var list_height = %ExpressionList.size.y
	self.size.y = clamp(list_height, 128, 800)
		
func make_row(e: AyagamiExpression, btn_group: ButtonGroup = null):
	var e_name = e.get_name()
		
	var row = HBoxContainer.new()
	var btn = CheckBox.new()
	btn.button_group = btn_group
	btn.text = e_name
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.name = "Toggle"
	row.add_child(btn)

	var duration = SpinBox.new()
	duration.step = 0.01
	duration.min_value = 0
	duration.max_value = 5.0
	duration.value = 0.5
	duration.custom_minimum_size = Vector2i(64, 0)
	btn.set_meta("spinner", duration)
	row.add_child(duration)
	
	btn.toggled.connect(
		func (toggled):
			toggle_expression(toggled, e, duration.value)
	)
	
	return row

func toggle_expression(activate: bool, expression: AyagamiExpression, fade: float):
	for b in buttons[expression]:
		b.set_pressed_no_signal(activate)
		
	var e_name: String = expression.get_name()
	var groups: Array = exp_controller.get("expression_groups/%s" % e_name)
	var tween = create_tween().set_parallel(true)
	if not groups.is_empty() and activate:
		for e2 in expressions:
			var e2_name = e2.get_name()
			if e_name == e2_name:
				continue
			var e_groups: Array = exp_controller.get("expression_groups/%s" % e2_name)
			if not Collections.intersect(groups, e_groups).is_empty():
				tween.tween_property(exp_controller, "weight/%s" % e2_name, 0.0, fade)
				for b in buttons[e2]:
					b.set_pressed_no_signal(false)
			
		tween.tween_property(exp_controller, "weight/%s" % e_name, 1.0, fade)
	elif activate:
		tween.tween_property(exp_controller, "weight/%s" % expression, 1.0, fade)
	else:
		tween.tween_property(exp_controller, "weight/%s" % expression, 0.0, fade)

func _on_close_requested() -> void:
	queue_free()
