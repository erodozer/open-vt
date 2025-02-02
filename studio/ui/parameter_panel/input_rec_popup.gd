extends Window

signal input_recorded(pressed)

func _input(event: InputEvent) -> void:
	var input_buffer = []
	if Input.is_key_pressed(KEY_SHIFT):
		input_buffer.append(KEY_SHIFT)
	if Input.is_key_pressed(KEY_CTRL):
		input_buffer.append(KEY_CTRL)
	if Input.is_key_pressed(KEY_ALT):
		input_buffer.append(KEY_ALT)
	
	%PressedInput.text = " + ".join(input_buffer.map(OS.get_keycode_string))
	
	if event is InputEventKey:
		if event.keycode in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META]:
			return
		if event.keycode == KEY_ESCAPE:
			input_recorded.emit([])
		else:
			input_buffer.append(event.keycode)
			input_recorded.emit(input_buffer)
	elif event is InputEventMouseButton and event.is_pressed():
		input_buffer.append(event.button_index)
		input_recorded.emit(input_buffer)
