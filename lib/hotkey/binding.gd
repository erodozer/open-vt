extends Node

enum Action {
	TOGGLE_EXPRESSION
}

var file: String
var action: Action

var button_1: String
var button_2: String
var button_3: String
var listen_to_input : bool :
	get():
		return button_1 or button_2 or button_3
var input_as_list: Array :
	get():
		var l = []
		for b in [button_1, button_2, button_3]:
			if b != "":
				l.append(b)
		return l

var screen_button: int
var screen_button_color: Color

var duration: float

var _active: bool = false
var _hold: bool = false
var deactivate_on_keyup = false

signal activate
signal deactivate

func _is_pressed(button: String) -> bool:
	var keycode = OS.find_keycode_from_string(button)
	if keycode != KEY_NONE:
		return GlobalInput.is_key_pressed(OS.find_keycode_from_string(button))
	if button.begins_with("MOUSE_"):
		if button == "MOUSE_BUTTON_LEFT":
			return Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		elif button == "MOUSE_BUTTON_RIGHT":
			return Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if button.begins_with("JOY_"):
		return false
		# return Input.is_joy_button_pressed(0, button)
	return true

func _process(delta: float) -> void:
	if not self.listen_to_input:
		return
		
	var b1 = _is_pressed(button_1)
	var b2 = _is_pressed(button_2)
	var b3 = _is_pressed(button_3)
	var activated = b1 and b2 and b3
	
	if activated and not _active and not _hold:
		_active = true
		_hold = true
		activate.emit()
	elif activated and _active and not _hold:
		_active = false
		_hold = true
		deactivate.emit()
	elif not activated:
		_hold = false
		if _active and deactivate_on_keyup:
			_active = false
			deactivate.emit()
