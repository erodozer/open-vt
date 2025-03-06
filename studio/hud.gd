extends "res://lib/popout_panel.gd"

var open
var group: ButtonGroup

@onready var panels = %Panels/Control
@onready var action_controller = %ActionController
@onready var action_editor = %ActionEditor
@onready var popup_btn = %PopoutBtn

func _ready() -> void:
	group = %ParameterBtn.button_group
	group.pressed.connect(
		func (button):
			if button != null and button.button_pressed:
				var panel = button.get_node(button.get_meta("panel"))
				_open_panel(panel)
			else:
				_close_panel()
	)
	
	on_popout_requested.connect(
		func ():
			get_window().unresizable = true
			self.size = Vector2i(580, 720)
			group.allow_unpress = false
			$Bg.show()
			popup_btn.hide()
			action_controller.popout(true)
			_close_panel()
	)
	
	on_popout.connect(
		func ():
			var curr = open
			if curr == null:
				curr = panels.get_child(0)
			open = null
			
			_open_panel(curr)
	)
	
	on_restore.connect(
		func ():
			self.size = get_parent_area_size()
			group.allow_unpress = true
			$Bg.hide()
			for p in panels.get_children():
				p.offset_right = p.size.x
			action_controller.restore()
			open == null
			_clear_buttons()
			popup_btn.show()
			get_window().unresizable = false
	)

func _close_panel():
	if open != null:
		open.create_tween().tween_property(
			open,
			"offset_right",
			open.size.x,
			0.3
		).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC).from(0)
		
		open = null

func _open_panel(panel):
	if panel.has_method("_refresh"):
		await panel._refresh()
	
	if panel == action_editor and is_floating:
		action_editor.popout()
		return
	
	if panel == open:
		return
	
	_close_panel()
	panel.create_tween().tween_property(
		panel,
		"offset_right",
		0,
		0.3
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC).from(panel.size.x)
	
	open = panel
	
func _clear_buttons():
	for b in group.get_buttons():
		b.button_pressed = false
	_close_panel()

func _on_model_changed(_model: Node) -> void:
	_clear_buttons()
	
func _on_stage_item_added(item: Node2D) -> void:
	_clear_buttons()
	
