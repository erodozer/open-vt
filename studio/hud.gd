extends Control

var open
var group: ButtonGroup

func _ready() -> void:
	group = %ParameterBtn.button_group
	group.pressed.connect(
		func (button):
			_close_panel()
			
			if button != null and button.button_pressed:
				var panel = button.get_node(button.get_meta("panel"))
				_open_panel(panel)
	)

func _close_panel():
	if open != null:
		open.create_tween().tween_property(
			open,
			"position",
			Vector2(size.x, 0),
			0.3
		).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC).from(Vector2(size.x - open.size.x, 0))
		
		open = null

func _open_panel(panel):
	if panel.has_method("_refresh"):
		await panel._refresh()
	panel.create_tween().tween_property(
		panel,
		"position",
		Vector2(size.x - panel.size.x, 0),
		0.3
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC).from(Vector2(size.x, 0))
	
	open = panel

func _on_transparency_toggled(toggled_on: bool) -> void:
	%BgFill.visible = !toggled_on

func _on_model_changed(_model: Node) -> void:
	%ModelBtn.button_pressed = false
	_close_panel()
	
func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if Input.is_key_pressed(KEY_CTRL) and Input.is_key_pressed(KEY_H):
			visible = not visible
			accept_event()

func _on_stage_item_added(item: Node2D) -> void:
	%ItemBtn.button_pressed = false
	_close_panel()
	
