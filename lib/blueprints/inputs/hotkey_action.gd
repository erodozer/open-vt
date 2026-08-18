extends "../vt_action.gd"

const HotkeyBinding = preload("./hotkey_binding.gd")

var hotkey:
	get():
		return %Handler

func get_type() -> StringName:
	return &"hotkey"
	
func serialize():
	return {
		"buttons": [hotkey.button_1, hotkey.button_2, hotkey.button_3]
	}
	
func get_input_slot_by_port(port: int) -> int:
	return -1
	
func get_input_port_by_name(slot: StringName) -> int:
	return -1
	
func get_output_slot_by_port(port: int) -> int:
	match port:
		0:
			return 1
		1:
			return 2
		_:
			return -1
	
func get_output_port_by_name(slot: StringName) -> int:
	match slot.to_lower():
		"pressed":
			return 0
		"released":
			return 1
		_:
			return -1

func deserialize(data: Dictionary):
	var binding = data.get("buttons", ["", "", ""])
	hotkey.button_1 = binding[0]
	hotkey.button_2 = binding[1]
	hotkey.button_3 = binding[2]
	
	%Input.text = " + ".join(hotkey.input_as_list)

func _on_input_pressed() -> void:
	%Modal.show()
	%InputRecPopup.show()

	%Modal.show()
	%InputRecPopup.grab_focus()
	
	var pressed: Array = await %InputRecPopup.input_recorded
	
	%Modal.hide()
	
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
