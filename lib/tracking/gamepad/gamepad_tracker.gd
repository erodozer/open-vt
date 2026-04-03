## Gamepad Tracking implements parameter compatibility with VTS and Nyarupad,
## This implementation is targeted for the sake of maintaining portability of models from VTS
##
## Nyarupad prefixes its custom parameters with NP_
##   Nyarupad also had support for mapping DPAD to Analog inputs
## Features from Nyarupad are also extended to VTS Gamepad Inputs

extends "../tracker.gd"

const DEADZONE = 0.1

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
		"input": ["NP_DPadUp"],
		"name": "D-Up",
		"key": KEY_W
	},
	{
		"input": ["NP_DPadDown"],
		"name": "D-Down",
		"key": KEY_S
	},
	{
		"input": ["NP_DPadLeft"],
		"name": "D-Left",
		"key": KEY_A
	},
	{
		"input": ["NP_DPadRight"],
		"name": "D-Right",
		"key": KEY_D
	},
	{
		"input": ["NP_ButtonA", "ControllerCross"],
		"name": "Cross/A",
		"key": KEY_J
	},
	{
		"input": ["NP_ButtonB", "ControllerCircle"],
		"name": "Circle/B",
		"key": KEY_K
	},
	{
		"input": ["NP_ButtonX", "ControllerSquare"],
		"name": "Square/X",
		"key": KEY_U
	},
	{
		"input": ["NP_ButtonY", "ControllerTriangle"],
		"name": "Triangle/Y",
		"key": KEY_I
	},
	{
		"input": ["NP_L1", "ControllerShoulderLeft"],
		"name": "L1/LB",
		"key": KEY_O
	},
	{
		"input": ["NP_L2", "ControllerTriggerLeft"],
		"name": "L2/LT",
		"key": KEY_P
	},
	{
		"input": ["NP_R1", "ControllerShoulderRight"],
		"name": "R1/RB",
		"key": KEY_L
	},
	{
		"input": ["NP_R2", "ControllerTriggerRight"],
		"name": "R2/RT",
		"key": KEY_SEMICOLON
	},
	{
		"input": ["NP_ButtonLS", "ControllerStickPressLeft"],
		"name": "L3/LS",
		"key": KEY_Y
	},
	{
		"input": ["NP_ButtonRS", "ControllerStickPressRight"],
		"name": "R3/RS",
		"key": KEY_H
	},
	{
		"input": ["NP_StartDown", "ControllerOptionRight"],
		"name": "Start/Menu",
		"key": KEY_ENTER
	},
	{
		"input": ["NP_SelectDown", "ControllerOptionLeft"],
		"name": "Opt/Back",
		"key": KEY_TAB
	},
	{
		"input": ["NP_LStickX", "ControllerStickLeftX"],
		"name": "LS X-",
		"key": KEY_A,
		"range": Vector2(0, -1.0)
	},
	{
		"input": ["NP_LStickX", "ControllerStickLeftX"],
		"name": "LS X+",
		"key": KEY_D
	},
	{
		"input": ["NP_LStickY", "ControllerStickLeftY"],
		"name": "LS Y-",
		"key": KEY_S,
		"range": Vector2(0, -1.0)
	},
	{
		"input": ["NP_LStickY", "ControllerStickLeftY"],
		"name": "LS Y+",
		"key": KEY_W
	},
	{
		"input": ["NP_RStickX", "ControllerStickRightX"],
		"name": "RS X-",
		"key": KEY_LEFT,
		"range": Vector2(0, -1.0)
	},
	{
		"input": ["NP_RStickX", "ControllerStickRightX"],
		"name": "RS X+",
		"key": KEY_RIGHT
	},
	{
		"input": ["NP_RStickY", "ControllerStickRightY"],
		"name": "RS Y-",
		"key": KEY_DOWN,
		"range": Vector2(0, -1.0)
	},
	{
		"input": ["NP_RStickY", "ControllerStickRightY"],
		"name": "RS Y+",
		"key": KEY_UP
	},
]

func _ready():
	# Nyarupad Inputs
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
	
	# VTS Gamepad Inputs
	Registry.add_parameter("ControllerDPadX", Vector2(-1.0, 1.0), 0.0)
	Registry.add_parameter("ControllerDPadY", Vector2(-1.0, 1.0), 0.0)
	Registry.add_parameter("ControllerStickLeftX", Vector2(-1.0, 1.0), 0.0)
	Registry.add_parameter("ControllerStickLeftY", Vector2(-1.0, 1.0), 0.0)
	Registry.add_parameter("ControllerStickRightX", Vector2(-1.0, 1.0), 0.0)
	Registry.add_parameter("ControllerStickRightY", Vector2(-1.0, 1.0), 0.0)
	Registry.add_parameter("ControllerStickPressLeft", Vector2(0, 1), 0.0)
	Registry.add_parameter("ControllerStickPressRight", Vector2(0, 1), 0.0)
	Registry.add_parameter("ControllerTriangle", Vector2(0, 1), 0.0)
	Registry.add_parameter("ControllerCross", Vector2(0, 1), 0.0)
	Registry.add_parameter("ControllerSquare", Vector2(0, 1), 0.0)
	Registry.add_parameter("ControllerCircle", Vector2(0, 1), 0.0)
	Registry.add_parameter("ControllerShoulderLeft", Vector2(0, 1), 0.0)
	Registry.add_parameter("ControllerTriggerLeft", Vector2(0, 1), 0.0)
	Registry.add_parameter("ControllerShoulderRight", Vector2(0, 1), 0.0)
	Registry.add_parameter("ControllerTriggerRight", Vector2(0, 1), 0.0)
	Registry.add_parameter("ControllerOptionLeft", Vector2(0, 1), 0.0)
	Registry.add_parameter("ControllerOptionRight", Vector2(0, 1), 0.0)
	Registry.add_parameter("ControllerHome", Vector2(0, 1), 0.0)
	Registry.add_parameter("ControllerTouchPadPress", Vector2(0, 1), 0.0)
	Registry.add_parameter("ControllerButtonsAnyLeft", Vector2(0, 1), 0.0)
	Registry.add_parameter("ControllerButtonsAnyRight", Vector2(0, 1), 0.0)
	Registry.add_parameter("ControllerButtonCountLeft", Vector2(0, 99), 0.0)
	Registry.add_parameter("ControllerButtonCountRight", Vector2(0, 99), 0.0)
	Registry.add_parameter("ControllerLean", Vector2(-1, 1), 0.0)
	Registry.add_parameter("ControllerThumbPosLeft", Vector2(0, 3), 0.0)
	Registry.add_parameter("ControllerThumbPosRight", Vector2(0, 3), 0.0)
	Registry.add_parameter("ControllerFingerPosLeft", Vector2(0, 2), 0.0)
	Registry.add_parameter("ControllerFingerPosRight", Vector2(0, 2), 0.0)
	Registry.add_parameter("ControllerOrientationX", Vector2(-60.0, 60.0), 0.0)
	Registry.add_parameter("ControllerOrientationY", Vector2(-60.0, 60.0), 0.0)
	Registry.add_parameter("ControllerOrientationZ", Vector2(-60.0, 60.0), 0.0)

func create_config() -> Node:
	var config = load("res://lib/tracking/gamepad/config.tscn").instantiate()
	config.tracker = self
	return config
	
func read_gamepad() -> Dictionary:
	return {
		"NP_ButtonA": Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_A),
		"ControllerCross": Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_A),
		"NP_ButtonB": Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_B),
		"ControllerCircle": Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_B),
		"NP_ButtonX": Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_X),
		"ControllerSquare": Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_X),
		"NP_ButtonY": Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_Y),
		"ControllerTriangle": Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_Y),
		"NP_L1": Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_LEFT_SHOULDER),
		"ControllerShoulderLeft": Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_LEFT_SHOULDER),
		"NP_R1": Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_RIGHT_SHOULDER),
		"ControllerShoulderRight": Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_RIGHT_SHOULDER),
		"NP_L2": Input.get_joy_axis(gamepad_index, JOY_AXIS_TRIGGER_LEFT),
		"ControllerTriggerLeft": Input.get_joy_axis(gamepad_index, JOY_AXIS_TRIGGER_LEFT),
		"NP_R2": Input.get_joy_axis(gamepad_index, JOY_AXIS_TRIGGER_RIGHT),
		"ControllerTriggerRight": Input.get_joy_axis(gamepad_index, JOY_AXIS_TRIGGER_RIGHT),
		"NP_ButtonLS": Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_LEFT_STICK),
		"ControllerStickPressLeft": Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_LEFT_STICK),
		"NP_ButtonRS": Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_RIGHT_STICK),
		"ControllerStickPressRight": Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_RIGHT_STICK),
		"NP_SelectDown": Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_BACK),
		"ControllerOptionLeft": Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_BACK),
		"NP_StartDown": Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_START),
		"ControllerOptionRight": Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_START),
		"NP_LStickX": Input.get_joy_axis(gamepad_index, JOY_AXIS_LEFT_X),
		"ControllerStickLeftX": Input.get_joy_axis(gamepad_index, JOY_AXIS_LEFT_X),
		"NP_LStickY": Input.get_joy_axis(gamepad_index, JOY_AXIS_LEFT_Y),
		"ControllerStickLeftY": Input.get_joy_axis(gamepad_index, JOY_AXIS_LEFT_Y),
		"NP_RStickX": Input.get_joy_axis(gamepad_index, JOY_AXIS_RIGHT_X),
		"ControllerStickRightX": Input.get_joy_axis(gamepad_index, JOY_AXIS_RIGHT_X),
		"NP_RStickY": Input.get_joy_axis(gamepad_index, JOY_AXIS_RIGHT_Y),
		"ControllerStickRightY": Input.get_joy_axis(gamepad_index, JOY_AXIS_RIGHT_Y),
		# nyarupad has discrete dpad bindings
		"NP_DPadDown": Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_DPAD_DOWN),
		"NP_DPadUp": Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_DPAD_UP),
		"NP_DPadLeft": Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_DPAD_LEFT),
		"NP_DPadRight": Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_DPAD_RIGHT),
		# TODO DS4 touchpad support
		# TODO DS4 gyro (requires Godot >= 4.7)
	}
	
func read_from_kb() -> Dictionary:
	var input = {}
	for mapping in keyboard_mapping:
		var input_bind = mapping.input
		var key = mapping.key
		var map_to_range = mapping.get("range", Vector2(0.0, 1.0))
		for i in input_bind:
			input[i] = input.get(i, 0.0) + (
				map_to_range.y if GlobalInput.is_key_pressed(key) else map_to_range.x
			)
	
	return input
	
var previous_l_thumb_pos: int = 0
var previous_r_thumb_pos: int = 0

func get_thumb_pos(side: bool, dpad: Vector2, stick: Vector2, stick_button: float, option: float) -> float:
	# on Option
	var pos = previous_l_thumb_pos if not side else previous_r_thumb_pos
	if option > 0.0:
		pos = 2
	# on stick
	elif stick.length() > DEADZONE:
		pos = 1
	elif stick_button > 0.0:
		pos = 1
	# on dpad
	elif dpad.length() > DEADZONE:
		pos = 0
	# TODO on touchpad (3)
	
	# record thumb state to blend between frames
	if side:
		previous_r_thumb_pos = pos
	else:
		previous_l_thumb_pos = pos
	
	return pos
	
func get_finger_pos(shoulder_button: float, trigger_button: float) -> float:
	if trigger_button > 0:
		if shoulder_button > 0:
			return 2 # both
		return 1 # trigger
	return 0 # shoulder at rest
	
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
	var l_stick = Vector2(
		inputs["NP_LStickX"],
		inputs["NP_LStickY"]
	)
	var r_stick = Vector2(
		inputs["NP_RStickX"],
		inputs["NP_RStickY"]
	)
	var r_down = is_button_pressed(face)
	var l_down = is_button_pressed(dpad)
	var l_thumb_pos = get_thumb_pos(
		false,
		l_thumb,
		l_stick,
		float(inputs["ControllerStickPressLeft"]),
		float(inputs["ControllerOptionLeft"])
	)
	var r_thumb_pos = get_thumb_pos(
		true,
		r_thumb,
		r_stick,
		float(inputs["ControllerStickPressRight"]),
		float(inputs["ControllerOptionRight"])
	)
	var l_finger_pos = get_finger_pos(
		float(inputs["ControllerShoulderLeft"]),
		float(inputs["ControllerTriggerLeft"])
	)
	var r_finger_pos = get_finger_pos(
		float(inputs["ControllerShoulderRight"]),
		float(inputs["ControllerTriggerRight"])
	)
	
	inputs.merge({
		"NP_LThumbX": l_thumb.x,
		"NP_LThumbY": l_thumb.y,
		"NP_RThumbX": r_thumb.x,
		"NP_RThumbY": r_thumb.y,
		"NP_RButtonDown": float(r_down),
		"NP_LButtonDown": float(l_down),
		
		"ControllerDPadX": l_thumb.x,
		"ControllerDPadY": l_thumb.y,
		"ControllerButtonsAnyRight": float(r_down),
		"ControllerButtonsAnyLeft": float(l_down),
		
		"ControllerThumbPosLeft": l_thumb_pos,
		"ControllerThumbPosRight": r_thumb_pos,
		"ControllerFingerPosLeft": l_finger_pos,
		"ControllerFingerPosRight": r_finger_pos,
	})
		
	if dpad_to_ls:
		inputs.merge({
			"NP_LStickX": (0.7 if l_thumb.length() > 1.0 else 1.0) * sign(l_thumb.x),
			"NP_LStickY": (0.7 if l_thumb.length() > 1.0 else 1.0) * sign(l_thumb.y),
			"ControllerStickLeftX": (0.7 if l_thumb.length() > 1.0 else 1.0) * sign(l_thumb.x),
			"ControllerStickLeftY": (0.7 if l_thumb.length() > 1.0 else 1.0) * sign(l_thumb.y)
		}, true)
	
	update(inputs)
