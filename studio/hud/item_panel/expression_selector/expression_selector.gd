extends Window

const VtModel = preload("res://lib/model/vt_model.gd")

var item: VtModel

func _ready():
	var exp_controller: AyagamiExpressionMutator = item.get_expression_controller()
	var expressions = exp_controller.expressions.duplicate()
	
	expressions.sort_custom(
		func (e, _e):
			return exp_controller.get("expression_groups/%s" % e.get_name()) == ""
	)
	var group = ""
	var btn_group: ButtonGroup = null
	for e in expressions:
		var e_group = exp_controller.get("expression_groups/%s" % e.get_name())
		if group != e_group:
			group = e_group
			var l = Label.new()
			l.text = group
			%ExpressionList.add_child(l)
			btn_group = ButtonGroup.new()
			btn_group.allow_unpress = true
		
		exp_controller.set("expression_groups/%s" % e.get_name(), group)
		
		var ename = e.get_name()
		
		var row = HBoxContainer.new()
		var btn = CheckBox.new()
		btn.button_group = btn_group
		btn.text = ename
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(btn)

		var duration = SpinBox.new()
		duration.step = 0.01
		duration.min_value = 0
		duration.max_value = 5.0
		duration.value = 0.5
		duration.custom_minimum_size = Vector2i(64, 0)
		btn.set_meta("spinner", duration)
		row.add_child(duration)
		
		var toggler = func (toggled: bool, group: ButtonGroup):
			var timing: float = duration.value
			if group and group.get_pressed_button() != null:
				timing = group.get_pressed_button().get_meta("spinner").value
			exp_controller.create_tween().tween_property(
				exp_controller,
				"weight/%s" % e.get_name(),
				1.0 if toggled else 0.0,
				timing
			)
			
		btn.toggled.connect(toggler.bind(btn_group))
		
		%ExpressionList.add_child(row)
	await get_tree().process_frame
	
	self.size.y = min(800, %ExpressionList.size.y)
		

func _on_close_requested() -> void:
	queue_free()
