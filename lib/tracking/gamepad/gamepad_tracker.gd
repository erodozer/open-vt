## Gamepad Tracking implements parameter compatibility with Nyarupad,
## the defacto tracking extension for VTS.  This implementation is
## targeted for the sake of maintaining portability of models from VTS
##
## Nyarupad prefixes its custom parameters with NP_

extends "../tracker.gd"

const DPAD = [
	"NP_DPadDown",
	"NP_DPadUp",
	"NP_DPadLeft",
	"NP_DPadRight",
]
const FACE = [
	"NP_ButtonA",
	"NP_ButtonB",
	"NP_ButtonX",
	"NP_ButtonY",
]

static func is_button_pressed(buttons):
	return true in buttons
	
static func get_thumb_axis(buttons):
	return Vector2(
		int(buttons[2]) - int(buttons[0]),
		int(buttons[3]) - int(buttons[1])
	)
	
static func is_face_pressed(inputs):
	return is_button_pressed([
		inputs["NP_ButtonA"],
		inputs["NP_ButtonB"],
		inputs["NP_ButtonX"],
		inputs["NP_ButtonY"]
	])
	
static func is_dpad_pressed(inputs):
	return is_button_pressed([
		inputs["NP_DPadDown"],
		inputs["NP_DPadRight"],
		inputs["NP_DPadLeft"],
		inputs["NP_DPadUp"],
	])

@export var gamepad_index = -1

@export var dpad_to_ls: bool = true

@export var keyboard_mapping: Array = [
	{
		"input": "NP_DPadUp",
		"name": "D-Up",
		"key": KEY_W
	},
	{
		"input": "NP_DPadDown",
		"name": "D-Down",
		"key": KEY_S
	},
	{
		"input": "NP_DPadLeft",
		"name": "D-Left",
		"key": KEY_A
	},
	{
		"input": "NP_DPadRight",
		"name": "D-Right",
		"key": KEY_D
	},
	{
		"input": "NP_ButtonA",
		"name": "Cross/A",
		"key": KEY_J
	},
	{
		"input": "NP_ButtonB",
		"name": "Circle/B",
		"key": KEY_K
	},
	{
		"input": "NP_ButtonX",
		"name": "Square/X",
		"key": KEY_U
	},
	{
		"input": "NP_ButtonY",
		"name": "Triangle/Y",
		"key": KEY_I
	},
	{
		"input": "NP_L1",
		"name": "L1/LB",
		"key": KEY_O
	},
	{
		"input": "NP_L2",
		"name": "L2/LT",
		"key": KEY_P
	},
	{
		"input": "NP_R1",
		"name": "R1/RB",
		"key": KEY_L
	},
	{
		"input": "NP_R2",
		"name": "R2/RT",
		"key": KEY_SEMICOLON
	},
	{
		"input": "NP_ButtonLS",
		"name": "L3/LS",
		"key": KEY_Y
	},
	{
		"input": "NP_ButtonRS",
		"name": "R3/RS",
		"key": KEY_H
	},
	{
		"input": "NP_StartDown",
		"name": "Start/Menu",
		"key": KEY_ENTER
	},
	{
		"input": "NP_SelectDown",
		"name": "Opt/Back",
		"key": KEY_TAB
	},
	{
		"input": "NP_LStickX",
		"name": "LS X-",
		"key": KEY_A,
		"range": Vector2(0, -1.0)
	},
	{
		"input": "NP_LStickX",
		"name": "LS X+",
		"key": KEY_D
	},
	{
		"input": "NP_LStickY",
		"name": "LS Y-",
		"key": KEY_S,
		"range": Vector2(0, -1.0)
	},
	{
		"input": "NP_LStickY",
		"name": "LS Y+",
		"key": KEY_W
	},
	{
		"input": "NP_RStickX",
		"name": "RS X-",
		"key": KEY_LEFT,
		"range": Vector2(0, -1.0)
	},
	{
		"input": "NP_RStickX",
		"name": "RS X+",
		"key": KEY_RIGHT
	},
	{
		"input": "NP_RStickY",
		"name": "RS Y-",
		"key": KEY_DOWN,
		"range": Vector2(0, -1.0)
	},
	{
		"input": "NP_RStickY",
		"name": "RS Y+",
		"key": KEY_UP
	},
]

func _ready():
	Registry.add_parameter("NP_DPadDown", Vector2(0, 1), 0.0)
	Registry.add_parameter("NP_DPadUp", Vector2(0, 1), 0.0)
	Registry.add_parameter("NP_DPadLeft", Vector2(0, 1), 0.0)
	Registry.add_parameter("NP_DPadRight", Vector2(0, 1), 0.0)
	Registry.add_parameter("NP_LButtonDown", Vector2(0, 1), 0.0)
	Registry.add_parameter("NP_RButtonDown", Vector2(0, 1), 0.0)
	Registry.add_parameter("NP_L2", Vector2(0, 1), 0.0)
	Registry.add_parameter("NP_L1", Vector2(0, 1), 0.0)
	Registry.add_parameter("NP_L2", Vector2(0, 1), 0.0)
	Registry.add_parameter("NP_R1", Vector2(0, 1), 0.0)
	Registry.add_parameter("NP_R2", Vector2(0, 1), 0.0)
	Registry.add_parameter("NP_ButtonLS", Vector2(0, 1), 0.0)
	Registry.add_parameter("NP_ButtonRS", Vector2(0, 1), 0.0)
	Registry.add_parameter("NP_ButtonA", Vector2(0, 1), 0.0)
	Registry.add_parameter("NP_ButtonB", Vector2(0, 1), 0.0)
	Registry.add_parameter("NP_ButtonX", Vector2(0, 1), 0.0)
	Registry.add_parameter("NP_ButtonY", Vector2(0, 1), 0.0)
	Registry.add_parameter("NP_StartDown", Vector2(0, 1), 0.0)
	Registry.add_parameter("NP_SelectDown", Vector2(0, 1), 0.0)
	Registry.add_parameter("NP_LStickX", Vector2(-1.0, 1.0), 0.0)
	Registry.add_parameter("NP_LStickY", Vector2(-1.0, 1.0), 0.0)
	Registry.add_parameter("NP_RThumbX", Vector2(-1.0, 1.0), 0.0)
	Registry.add_parameter("NP_RThumbY", Vector2(-1.0, 1.0), 0.0)
	Registry.add_parameter("NP_RStickX", Vector2(-1.0, 1.0), 0.0)
	Registry.add_parameter("NP_RStickY", Vector2(-1.0, 1.0), 0.0)

func create_config() -> Node:
	var config = load("res://lib/tracking/gamepad/config.tscn").instantiate()
	config.tracker = self
	return config
	
func read_gamepad() -> Dictionary:
	return {
		"NP_ButtonA": Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_A),
		"NP_ButtonB": Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_B),
		"NP_ButtonX": Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_X),
		"NP_ButtonY": Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_Y),
		"NP_L1": Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_LEFT_SHOULDER),
		"NP_R1": Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_RIGHT_SHOULDER),
		"NP_L2": Input.get_joy_axis(gamepad_index, JOY_AXIS_TRIGGER_LEFT),
		"NP_R2": Input.get_joy_axis(gamepad_index, JOY_AXIS_TRIGGER_RIGHT),
		"NP_ButtonLS": Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_LEFT_STICK),
		"NP_ButtonRS": Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_RIGHT_STICK),
		"NP_SelectDown": Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_BACK),
		"NP_StartDown": Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_START),
		"NP_LStickX": Input.get_joy_axis(gamepad_index, JOY_AXIS_LEFT_X),
		"NP_LStickY": Input.get_joy_axis(gamepad_index, JOY_AXIS_LEFT_Y),
		"NP_RStickX": Input.get_joy_axis(gamepad_index, JOY_AXIS_RIGHT_X),
		"NP_RStickY": Input.get_joy_axis(gamepad_index, JOY_AXIS_RIGHT_Y),
		"NP_DPadDown": Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_DPAD_DOWN),
		"NP_DPadUp": Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_DPAD_UP),
		"NP_DPadLeft": Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_DPAD_LEFT),
		"NP_DPadRight": Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_DPAD_RIGHT),
	}
	
func read_from_kb() -> Dictionary:
	var input = {}
	for mapping in keyboard_mapping:
		var np_input = mapping.input
		var key = mapping.key
		var map_to_range = mapping.get("range", Vector2(0.0, 1.0))
		input[np_input] = input.get(np_input, 0.0) + (
			map_to_range.y if GlobalInput.is_key_pressed(key) else map_to_range.x
		)
	
	return input
	
func _process(_delta: float) -> void:
	var inputs: Dictionary
	if gamepad_index < 0: # keyboard input
		inputs = read_from_kb()
	else:
		inputs = read_gamepad()
		
	# set aggregate fields
	var dpad = [
		inputs["NP_DPadDown"],
		inputs["NP_DPadRight"],
		inputs["NP_DPadLeft"],
		inputs["NP_DPadUp"],
	]
	var face = [
		inputs["NP_ButtonA"],
		inputs["NP_ButtonB"],
		inputs["NP_ButtonX"],
		inputs["NP_ButtonY"],
	]
	var l_thumb = get_thumb_axis(dpad)
	var r_thumb = get_thumb_axis(face)
	var r_down = is_button_pressed(face)
	var l_down = is_button_pressed(dpad)
	
	if dpad_to_ls:
		inputs.merge({
			"NP_LStickX": (0.7 if l_thumb.length() > 1.0 else 1.0) * sign(l_thumb.x),
			"NP_LStickY": (0.7 if l_thumb.length() > 1.0 else 1.0) * sign(l_thumb.y)
		})
	
	inputs.merge({
		"NP_LThumbX": l_thumb.x,
		"NP_LThumbY": l_thumb.y,
		"NP_RThumbX": r_thumb.x,
		"NP_RThumbY": r_thumb.y,
		"NP_RButtonDown": float(r_down),
		"NP_LButtonDown": float(l_down),
	})
		
	update(inputs)
