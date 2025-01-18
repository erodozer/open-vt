extends Node

# for compatibility with VTS and its Stream to PC functionality
# it's important to maintain exact enum order, as they are serialized by the ordinal
enum Inputs {
	UNSET,
	FACE_POSITION_X,
	FACE_POSITION_Y,
	FACE_POSITION_Z,
	FACE_ANGLE_X,
	FACE_ANGLE_Y,
	FACE_ANGLE_Z,
	MOUTH_SMILE,
	MOUTH_OPEN,
	BROWS,
	TONGUE_OUT, # iOS/Android only
	EYE_OPEN_LEFT,
	EYE_OPEN_RIGHT,
	EYE_LEFT_X,
	EYE_LEFT_Y,
	EYE_RIGHT_X,
	EYE_RIGHT_Y,
	CHEEK_PUFF, # iOS only
	FACE_ANGRY, # iOS only
	BROW_LEFT_Y,
	BROW_RIGHT_Y,
	MOUSE_POSITION_X,
	MOUSE_POSITION_Y,
	# microphone
	VOICE_VOLUME,
	VOICE_FREQUENCY,
	VOICE_VOLUME_PLUS_MOUTH_OPEN,
	VOICE_FREQUENCY_PLUS_MOUTH_SMILE,
	MOUTH_X,
	# pc only
	HAND_LEFT_FOUND,
	HAND_RIGHT_FOUND,
	BOTH_HANDS_FOUND,
	HAND_DISTANCE,
	HAND_LEFT_POSITION_X,
	HAND_LEFT_POSITION_Y,
	HAND_LEFT_POSITION_Z,
	HAND_RIGHT_POSITION_X,
	HAND_RIGHT_POSITION_Y,
	HAND_RIGHT_POSITION_Z,
	HAND_LEFT_ANGLE_X,
	HAND_LEFT_ANGLE_Z,
	HAND_RIGHT_ANGLE_X,
	HAND_RIGHT_ANGLE_Z,
	HAND_LEFT_OPEN,
	HAND_RIGHT_OPEN,
	HAND_LEFT_FINGER_1_THUMB,
	HAND_LEFT_FINGER_2_INDEX,
	HAND_LEFT_FINGER_3_MIDDLE,
	HAND_LEFT_FINGER_4_RING,
	HAND_LEFT_FINGER_5_PINKY,
	HAND_RIGHT_FINGER_1_THUMB,
	HAND_RIGHT_FINGER_2_INDEX,
	HAND_RIGHT_FINGER_3_MIDDLE,
	HAND_RIGHT_FINGER_4_RING,
	HAND_RIGHT_FINGER_5_PINKY,
	# more voice
	VOICE_A,
	VOICE_I,
	VOICE_U,
	VOICE_E,
	VOICE_O,
	VOICE_SILENCE
}

const Meta = {
	Inputs.FACE_POSITION_X: {
		"range": Vector2(-15, 15),
	},
	Inputs.FACE_POSITION_Y: {
		"range": Vector2(-15, 15),
	},
	Inputs.FACE_POSITION_Z: {
		"range": Vector2(-10, 10),
	},
	Inputs.FACE_ANGLE_X: {
		"range": Vector2(-30, 30),
	},
	Inputs.FACE_ANGLE_Y: {
		"range": Vector2(-30, 30),
	},
	Inputs.FACE_ANGLE_Z: {
		"range": Vector2(-90, 90),
	},
	Inputs.MOUTH_SMILE: {
		"range": Vector2(0, 1),
	},
	Inputs.MOUTH_OPEN: {
		"range": Vector2(0, 1),
	},
	Inputs.MOUTH_X: {
		"range": Vector2(-1, 1),
	},
	Inputs.BROWS: {
		"range": Vector2(0, 1),
	},
	Inputs.TONGUE_OUT: {
		"range": Vector2(0, 1),
	},
	Inputs.CHEEK_PUFF: {
		"range": Vector2(0, 1),
	},
	Inputs.FACE_ANGRY: {
		"range": Vector2(0, 1),
	},
	Inputs.BROW_LEFT_Y: {
		"range": Vector2(0, 1),
	},
	Inputs.BROW_RIGHT_Y: {
		"range": Vector2(0, 1),
	},
	Inputs.EYE_LEFT_X: {
		"range": Vector2(-1, 1),
	},
	Inputs.EYE_LEFT_Y: {
		"range": Vector2(-1, 1),
	},
	Inputs.EYE_RIGHT_X: {
		"range": Vector2(-1, 1),
	},
	Inputs.EYE_RIGHT_Y: {
		"range": Vector2(-1, 1),
	},
	Inputs.EYE_OPEN_LEFT: {
		"range": Vector2(0, 1),
		"default": 1
	},
	Inputs.EYE_OPEN_RIGHT: {
		"range": Vector2(0, 1),
		"default": 1
	},
	Inputs.MOUSE_POSITION_X: {
		"range": Vector2(-1, 1),
	},
	Inputs.MOUSE_POSITION_Y: {
		"range": Vector2(-1, 1),
	},
	Inputs.VOICE_VOLUME: {
		"range": Vector2(0, 1),
	},
	Inputs.VOICE_FREQUENCY: {
		"range": Vector2(0, 1),
	},
	Inputs.VOICE_VOLUME_PLUS_MOUTH_OPEN: {
		"range": Vector2(0, 1),
	},
	Inputs.VOICE_FREQUENCY_PLUS_MOUTH_SMILE: {
		"range": Vector2(0, 1),
	},
	Inputs.VOICE_A: {
		"range": Vector2(0, 1),
	},
	Inputs.VOICE_E: {
		"range": Vector2(0, 1),
	},
	Inputs.VOICE_I: {
		"range": Vector2(0, 1),
	},
	Inputs.VOICE_O: {
		"range": Vector2(0, 1),
	},
	Inputs.VOICE_U: {
		"range": Vector2(0, 1),
	},
	Inputs.VOICE_SILENCE: {
		"range": Vector2(0, 1),
	},
}

var parameters = {}

static func clamp_to_range(value: float, param: Inputs):
	return clamp(
		value,
		Meta[param].range.x, Meta[param].range.y
	)

func create_config() -> Node:
	return null
