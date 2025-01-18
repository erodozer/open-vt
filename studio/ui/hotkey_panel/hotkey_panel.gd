extends PanelContainer

const VtModel = preload("res://lib/model/vt_model.gd")
const HotkeyBinding = preload("res://lib/hotkey/binding.gd")

@onready var list = get_node("%List")

func _ready() -> void:
	set_process_input(true)

func _on_model_manager_model_changed(model: VtModel) -> void:
	for c in list.get_children():
		c.queue_free()
		
	for binding in model.hotkeys:
		var panel = preload("./hotkey_setting.tscn").instantiate()
		panel.set_meta("hotkey", binding)
		panel.get_node("%HotkeyName").text = binding.name
		match binding.action:
			HotkeyBinding.Action.TOGGLE_EXPRESSION:
				panel.get_node("%ActionSelect").text = "Toggle Expression (%s)" % binding.file.get_file()
		if binding.listen_to_input:
			panel.get_node("%InputBinding").text = " + ".join(binding.input_as_list)
		else:
			panel.get_node("%InputBinding").text = ""
		panel.get_node("%FadeDuration").value = binding.duration
		panel.get_node("%Rec").pressed.connect(record_input.bind(panel))
		
		list.add_child(panel)

func record_input(setting):
	var hotkey = setting.get_meta("hotkey")
	
	%Modal.visible = true
	%InputRecPopup.show()
	%InputRecPopup.grab_focus()
	
	var pressed: Array = await %InputRecPopup.input_recorded
	
	%InputRecPopup.hide()
	%Modal.visible = false
	
	if len(pressed) > 0:
		hotkey.button_1 = OS.get_keycode_string(pressed[0])
	else:
		hotkey.button_1 = ""
	if len(pressed) > 1:
		hotkey.button_2 = OS.get_keycode_string(pressed[1])
	else:
		hotkey.button_2 = ""
	if len(pressed) > 2:
		hotkey.button_3 = OS.get_keycode_string(pressed[2])
	else:
		hotkey.button_3 = ""
	
	setting.get_node("%InputBinding").text = " + ".join(hotkey.input_as_list)
