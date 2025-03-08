extends "../vt_action.gd"

const HotkeyBinding = preload("./hotkey_binding.gd")

@onready var hotkey = %Handler

func _on_input_pressed() -> void:
	%Modal.show()
	%InputRecPopup.show()

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
	
	%Input.text = " + ".join(hotkey.input_as_list)
	
func _on_handler_activate() -> void:
	slot_updated.emit(0)
	var t = create_tween()
	t.tween_property(
		%Pressed/ColorRect, "modulate", Color.WHITE, 0.15
	).from(Color.TRANSPARENT)
	t.tween_property(
		%Pressed/ColorRect, "modulate", Color.TRANSPARENT, 0.1
	)

func _on_handler_deactivate() -> void:
	slot_updated.emit(1)
	var t = create_tween()
	t.tween_property(
		%Released/ColorRect, "modulate", Color.WHITE, 0.15
	).from(Color.TRANSPARENT)
	t.tween_property(
		%Released/ColorRect, "modulate", Color.TRANSPARENT, 0.1
	)
