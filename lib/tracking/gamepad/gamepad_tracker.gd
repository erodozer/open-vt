## Gamepad Tracking implements parameter compatibility with Nyarupad,
## the defacto tracking extension for VTS.  This implementation is
## targeted for the sake of maintaining portability of models from VTS
##
## Nyarupad prefixes its custom parameters with NP_

extends "../tracker.gd"

var gamepad_index = 0

func _ready():
	Registry.add_parameter("NP_L1", Vector2(0, 1), 0.0)
	Registry.add_parameter("NP_L2", Vector2(0, 1), 0.0)
	Registry.add_parameter("NP_R1", Vector2(0, 1), 0.0)
	Registry.add_parameter("NP_R2", Vector2(0, 1), 0.0)
	Registry.add_parameter("NP_LStickX", Vector2(-1.0, 1.0), 0.0)
	Registry.add_parameter("NP_LStickY", Vector2(-1.0, 1.0), 0.0)
	Registry.add_parameter("NP_RStickX", Vector2(-1.0, 1.0), 0.0)
	Registry.add_parameter("NP_RStickY", Vector2(-1.0, 1.0), 0.0)

func _process(delta: float) -> void:
	parameters = {
		"NP_RButtonDown":
			Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_A) or \
			Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_B) or \
			Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_X) or \
			Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_Y)
		,
		"NP_LButtonDown":
			Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_DPAD_DOWN) or \
			Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_DPAD_UP) or \
			Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_DPAD_LEFT) or \
			Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_DPAD_RIGHT)
		,
		"NP_L1": Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_LEFT_SHOULDER),
		"NP_R1": Input.is_joy_button_pressed(gamepad_index, JOY_BUTTON_RIGHT_SHOULDER),
		"NP_L2": Input.get_joy_axis(gamepad_index, JOY_AXIS_TRIGGER_LEFT),
		"NP_R2": Input.get_joy_axis(gamepad_index, JOY_AXIS_TRIGGER_RIGHT),
		"NP_LStickX": Input.get_joy_axis(0, JOY_AXIS_LEFT_X),
		"NP_LStickY": Input.get_joy_axis(0, JOY_AXIS_LEFT_Y),
		"NP_RStickX": Input.get_joy_axis(0, JOY_AXIS_RIGHT_X),
		"NP_RStickY": Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y),
	}
	
