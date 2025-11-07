## Gamepad Tracking implements parameter compatibility with Nyarupad,
## the defacto tracking extension for VTS.  This implementation is
## targeted for the sake of maintaining portability of models from VTS
##
## Nyarupad prefixes its custom parameters with NP_

extends "../tracker.gd"

var gamepad_index = 0

@export var dpad_to_ls: bool = true

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

func _process(_delta: float) -> void:
	var dpad = [
		Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_DPAD_DOWN),
		Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_DPAD_UP),
		Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_DPAD_LEFT),
		Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_DPAD_RIGHT),
	]
	var face = [
		Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_A),
		Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_B),
		Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_X),
		Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_Y)
	]
	var l_thumb = Vector2(
		int(dpad[3]) - int(dpad[2]),
		int(dpad[1]) - int(dpad[0])
	)
	var l_stick = Vector2(
		((0.7 if l_thumb.length() > 1.0 else 1.0) * sign(l_thumb.x)) if dpad_to_ls else Input.get_joy_axis(gamepad_index, JOY_AXIS_LEFT_X),
		((0.7 if l_thumb.length() > 1.0 else 1.0) * sign(l_thumb.y)) if dpad_to_ls else Input.get_joy_axis(gamepad_index, JOY_AXIS_LEFT_Y),
	)
	var r_thumb = Vector2(
		int(face[1]) - int(face[2]),
		int(face[3]) - int(face[0])
	)
	
	update({
		"NP_RButtonDown": face.has(true),
		"NP_LButtonDown": dpad.has(true),
		"NP_ButtonA": float(face[0]),
		"NP_ButtonB": float(face[1]),
		"NP_ButtonX": float(face[2]),
		"NP_ButtonY": float(face[3]),
		"NP_L1": Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_LEFT_SHOULDER),
		"NP_R1": Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_RIGHT_SHOULDER),
		"NP_L2": Input.get_joy_axis(gamepad_index, JOY_AXIS_TRIGGER_LEFT),
		"NP_R2": Input.get_joy_axis(gamepad_index, JOY_AXIS_TRIGGER_RIGHT),
		"NP_ButtonLS": Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_LEFT_STICK),
		"NP_ButtonRS": Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_RIGHT_STICK),
		"NP_SelectDown": Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_BACK),
		"NP_StartDown": Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_START),
		"NP_LStickX": l_stick.x,
		"NP_LStickY": l_stick.y,
		"NP_RStickX": Input.get_joy_axis(0, JOY_AXIS_RIGHT_X),
		"NP_RStickY": Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y),
		"NP_LThumbX": l_thumb.x,
		"NP_LThumbY": l_thumb.y,
		"NP_RThumbX": r_thumb.x,
		"NP_RThumbY": r_thumb.y,
		"NP_DPadDown": float(dpad[0]),
		"NP_DPadUp": float(dpad[1]),
		"NP_DPadLeft": float(dpad[2]),
		"NP_DPadRight": float(dpad[3]),
	})
	
