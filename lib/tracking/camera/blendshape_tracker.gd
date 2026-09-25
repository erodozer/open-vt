extends "res://lib/tracking/interpolated_tracker.gd"

const BLENDSHAPE_ENUM = [
	# Left Eye
	"EyeBlinkLeft",
	"EyeLookDownLeft",
	"EyeLookInLeft",
	"EyeLookOutLeft",
	"EyeLookUpLeft",
	"EyeSquintLeft",
	"EyeWideLeft",

	# Right Eye
	"EyeBlinkRight",
	"EyeLookDownRight",
	"EyeLookInRight",
	"EyeLookOutRight",
	"EyeLookUpRight",
	"EyeSquintRight",
	"EyeWideRight",

	# Mouth and Jaw
	"JawForward",
	"JawRight",
	"JawLeft",
	"JawOpen",
	"MouthClose",
	"MouthFunnel",
	"MouthPucker",
	"MouthLeft",
	"MouthRight",
	"MouthSmileLeft",
	"MouthSmileRight",
	"MouthFrownLeft",
	"MouthFrownRight",
	"MouthDimpleLeft",
	"MouthDimpleRight",
	"MouthStretchLeft",
	"MouthStretchRight",
	"MouthRollLower",
	"MouthRollUpper",
	"MouthShrugLower",
	"MouthShrugUpper",
	"MouthPressLeft",
	"MouthPressRight",
	"MouthLowerDownLeft",
	"MouthLowerDownRight",
	"MouthUpperUpLeft",
	"MouthUpperUpRight",

	# Eyebrows, Cheeks, and Nose
	"BrowDownLeft",
	"BrowDownRight",
	"BrowInnerUp",
	"BrowOuterUpLeft",
	"BrowOuterUpRight",
	"CheekPuff",
	"CheekSquintLeft",
	"CheekSquintRight",
	"NoseSneerLeft", 
	"NoseSneerRight",
	
	# Tongue
    "TongueOut"
]

## Joint tracking flags
const JOINT_TRACKING = \
	XRBodyTracker.JOINT_FLAG_ORIENTATION_TRACKED | \
	XRBodyTracker.JOINT_FLAG_ORIENTATION_VALID | \
	XRBodyTracker.JOINT_FLAG_POSITION_TRACKED | \
	XRBodyTracker.JOINT_FLAG_POSITION_VALID
	
static var tracker: XRBodyTracker = XRBodyTracker.new()
	
static func _static_init() -> void:
	# iOS/ARKit BlendShapes
	for blendshape in BLENDSHAPE_ENUM:
		Registry.add_parameter(blendshape, Vector2(0, 1), 0.0, "iOSBlendShape")
	
	tracker.name = "/arkit/head"
	tracker.body_flags = XRBodyTracker.BODY_FLAG_UPPER_BODY_SUPPORTED
	for i in range(XRBodyTracker.JOINT_MAX):
		tracker.set_joint_flags(i, 0)
	tracker.set_joint_flags(XRBodyTracker.JOINT_HEAD, JOINT_TRACKING)
	tracker.set_joint_flags(XRBodyTracker.JOINT_ROOT, JOINT_TRACKING)
	
	XRServer.add_tracker(tracker)
	
func _ready() -> void:
	reset()

func reset():
	update(Registry.parameters_in_group("iOSBlendShape").reduce(
		func (acc, parameter):
			acc[parameter] = Registry.get_default(parameter)
			return acc,
		{}
	))
