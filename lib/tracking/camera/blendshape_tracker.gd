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

func update(p: Dictionary):
	# inject standard ARKit to VTS named parameters adapters for ease of adoption
	var face_rotation = tracker.get_joint_transform(XRBodyTracker.JOINT_HEAD).basis.get_euler()
	var body_position = tracker.get_joint_transform(XRBodyTracker.JOINT_ROOT).origin
	p["FaceAngleX"] = rad_to_deg(face_rotation.y) * 0.66
	p["FaceAngleY"] = rad_to_deg(face_rotation.x) * -0.66
	p["FaceAngleZ"] = rad_to_deg(face_rotation.z) * -0.66
	
	p["FacePositionX"] = -body_position.x
	p["FacePositionY"] = body_position.y
	p["FacePositionZ"] = -body_position.z
	
	p["EyeRightX"] = p.get("EyeLookInRight", 0.0) - .1 - p.get("EyeLookOutRight", 0.0)
	p["EyeRightY"] = p.get("EyeLookUpRight", 0.0) - p.get("EyeLookDownRight", 0.0) - (p.get("BrowOuterUpRight", 0.0) * .15)
	p["EyeLeftX"] = p.get("EyeLookInLeft", 0.0) - .1 - p.get("EyeLookOutLeft", 0.0)
	p["EyeLeftY"] = p.get("EyeLookUpLeft", 0.0) - p.get("EyeLookDownLeft", 0.0) - (p.get("BrowOuterUpLeft", 0.0) * .15)
	p["EyeOpenRight"] = .5 + (p.get("EyeWideRight", 0.0) - p.get("EyeBlinkRight", 0.0)) * 0.8
	p["EyeOpenLeft"] = .5 + (p.get("EyeWideLeft", 0.0) - p.get("EyeBlinkLeft", 0.0)) * 0.8

	p["MouthOpen"] = p.get("JawOpen", 0.0) - p.get("MouthClose", 0.0) - (p.get("MouthRollUpper", 0.0) + p.get("MouthRollLower", 0.0) + p.get("MouthFunnel", 0.0)) * .2
	p["MouthSmile"] = 2 - (
		(p.get("MouthFrownLeft", 0.0) + p.get("MouthFrownRight", 0.0) + p.get("MouthPucker", 0.0)) +
		((
			(p.get("MouthSmileRight", 0.0) + p.get("MouthSmileLeft", 0.0)) +
			((p.get("MouthDimpleLeft", 0.0) + p.get("MouthDimpleRight", 0.0)) * 0.5)
		) * 0.25)
	)
	p["MouthX"] = (p.get("MouthLeft", 0.0) - p.get("MouthRight", 0.0)) + (p.get("MouthSmileLeft", 0.0) - p.get("MouthSmileRight", 0.0))
	p["Brows"] = 0.5 + (p.get("BrowOuterUpRight", 0.0) + p.get("BrowOuterUpRight", 0.0) - p.get("BrowDownLeft", 0.0) - p.get("BrowDownRight", 0.0)) * 0.25
	
	super.update(p)
