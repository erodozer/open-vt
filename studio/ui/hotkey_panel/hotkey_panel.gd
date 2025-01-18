extends PanelContainer

const VtModel = preload("res://lib/model/vt_model.gd")
const HotkeyBinding = preload("res://lib/hotkey/binding.gd")

@onready var list = get_node("%List")

func _on_model_manager_model_changed(model: VtModel) -> void:
	for c in list.get_children():
		c.queue_free()
		
	for binding in model.hotkeys:
		var panel = preload("./hotkey_setting.tscn").instantiate()
		panel.get_node("%HotkeyName").text = binding.name
		match binding.action:
			HotkeyBinding.Action.TOGGLE_EXPRESSION:
				panel.get_node("%ActionSelect").text = "Toggle Expression (%s)" % binding.file.get_file()
		panel.get_node("%Button1").text = binding.button_1
		panel.get_node("%Button2").text = binding.button_2
		panel.get_node("%Button3").text = binding.button_3
		panel.get_node("%FadeDuration").value = binding.duration
		
		list.add_child(panel)
