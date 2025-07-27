extends "res://lib/popout_panel.gd"

var open
var group: ButtonGroup

@onready var popup_bg = %Bg
@onready var panels = %Panels
@onready var action_controller = %ActionController
@onready var action_editor = %ActionEditor
@onready var popup_btn = %PopoutBtn

func _ready() -> void:
	group = %ParameterBtn.button_group
	group.pressed.connect(
		func (button):
			if button.get_meta("panel") == null:
				return
			if button != null and button.button_pressed:
				var panel = button.get_node(button.get_meta("panel"))
				_open_panel(panel)
			else:
				_close_panel()
	)
	
	on_popout_requested.connect(
		func ():
			# get_window().unresizable = true
			action_controller.popout(true)
			self.size = Vector2i(580, 720)
			group.allow_unpress = false
			popup_bg.show()
			popup_btn.hide()
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
			popup_bg.hide()
			for p in panels.get_children():
				if p is Control:
					p.offset_right = p.size.x
			action_controller.restore()
			open == null
			_clear_buttons()
			popup_btn.show()
			# get_window().unresizable = false
	)
	
	var stage = get_tree().get_first_node_in_group("system:stage")
	if stage:
		stage.item_added.connect(
			func (_item):
				_clear_buttons()
		)
		stage.model_changed.connect(
			func (_model):
				_clear_buttons()
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
	if panel != null and panel.has_method("_refresh"):
		await panel._refresh()
	
	if panel == open:
		return
	
	_close_panel()
	if panel != null:
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

func load_settings(settings: Dictionary):
	super.load_settings(settings)
	
	var do_popup = settings.get("popout_controls", false)
	if do_popup:
		await get_tree().process_frame
		self.popout()
	
func save_settings(settings: Dictionary):
	super.save_settings(settings)
	
	settings["popout_controls"] = self.is_floating
	
func _on_screenshot_btn_pressed() -> void:
	var stage = get_tree().get_first_node_in_group("system:stage")
	stage.get_node("ModelLayer")
	await Screenshot.snap(stage.get_viewport())
	
