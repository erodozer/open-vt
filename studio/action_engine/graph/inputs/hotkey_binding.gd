extends Node

static var NO_BINDING = func ():
	return true

var button_1: String :
	set(v):
		button_1 = v
		input_bindings[0] = _map_input(v)
var button_2: String :
	set(v):
		button_2 = v
		input_bindings[1] = _map_input(v)
var button_3: String :
	set(v):
		button_3 = v
		input_bindings[2] = _map_input(v)

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

var input_bindings: Array[Callable] = [
	NO_BINDING,
	NO_BINDING,
	NO_BINDING
]

signal activate
signal deactivate

func load_from_vts(hotkey: Dictionary):
	name = hotkey.Name
	self.button_1 = hotkey.Triggers.Trigger1
	self.button_2 = hotkey.Triggers.Trigger2
	self.button_3 = hotkey.Triggers.Trigger3
	screen_button = hotkey.Triggers.ScreenButton
	screen_button_color = Color(
		hotkey.OnScreenHotkeyColor.r,
		hotkey.OnScreenHotkeyColor.g,
		hotkey.OnScreenHotkeyColor.b,
		hotkey.OnScreenHotkeyColor.a
	)
	
func _map_input(button: String) -> Callable:
	var keycode = OS.find_keycode_from_string(button)
	if keycode != KEY_NONE:
		return GlobalInput.is_key_pressed.bind(keycode)
	if button.to_lower().contains("mouse"):
		if button == "MOUSE_BUTTON_LEFT" or button == "LeftMouseButton":
			return Input.is_mouse_button_pressed.bind(MOUSE_BUTTON_LEFT)
		elif button == "MOUSE_BUTTON_RIGHT" or button == "RightMouseButton":
			return Input.is_mouse_button_pressed.bind(MOUSE_BUTTON_RIGHT)
	return NO_BINDING

func _process(delta: float) -> void:
	if not self.listen_to_input:
		return
	
	var activated = true
	for p in input_bindings:
		activated = activated and p.call()
	
	if activated and not _active:
		_active = true
		activate.emit()
	elif _active and not activated:
		_active = false
		deactivate.emit()
