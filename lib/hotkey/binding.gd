extends Node

enum Action {
	TOGGLE_EXPRESSION
}

var file: String
var action: Action

var button_1: String
var button_2: String
var button_3: String
var _listen_to_input : bool :
	get():
		return button_1 or button_2 or button_3

var screen_button: int
var screen_button_color: Color

var duration: float

var _active: bool = false
var _hold: bool = false
var deactivate_on_keyup = false

signal activate
signal deactivate

func _is_pressed(button) -> bool:
	if button.starts_with("KEY_"):
		return Input.is_key_pressed(button)
	if button.starts_with("MOUSE_"):
		return Input.is_mouse_button_pressed(button)
	if button.starts_with("JOY_"):
		return Input.is_joy_button_pressed(0, button)
	return true

func _process(delta: float) -> void:
	if not _listen_to_input:
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
