extends "./blueprint_loader.gd"

# map VRM bone names to XR Joints
# names based on VRM 1.0 humanoid specification
# https://github.com/vrm-c/vrm-specification/blob/master/specification/VRMC_vrm-1.0/humanoid.md#list-of-humanoid-bones
const DEFAULT_BONE_MAP = {
	"root": XRBodyTracker.JOINT_ROOT,
	# torso
	"neck":       XRBodyTracker.JOINT_NECK,
	"chest":      XRBodyTracker.JOINT_CHEST,
	"upperChest": XRBodyTracker.JOINT_UPPER_CHEST,
	"hips":       XRBodyTracker.JOINT_HIPS,
	"spine":      XRBodyTracker.JOINT_SPINE,
	# head
	"head": XRBodyTracker.JOINT_HEAD,
	# leg
	"leftUpperLeg":  XRBodyTracker.JOINT_LEFT_UPPER_LEG,
	"leftLowerLeg":  XRBodyTracker.JOINT_LEFT_LOWER_LEG,
	"leftFoot":      XRBodyTracker.JOINT_LEFT_FOOT,
	"leftToes":      XRBodyTracker.JOINT_LEFT_TOES,
	"rightUpperLeg": XRBodyTracker.JOINT_RIGHT_UPPER_LEG,
	"rightLowerLeg": XRBodyTracker.JOINT_RIGHT_LOWER_LEG,
	"rightFoot":     XRBodyTracker.JOINT_RIGHT_FOOT,
	"rightToes":     XRBodyTracker.JOINT_RIGHT_TOES,
	# arm
	"leftShoulder":  XRBodyTracker.JOINT_LEFT_SHOULDER,
	"leftUpperArm":  XRBodyTracker.JOINT_LEFT_UPPER_ARM,
	"leftLowerArm":  XRBodyTracker.JOINT_LEFT_LOWER_ARM,
	"leftHand":      XRBodyTracker.JOINT_LEFT_HAND,
	"rightShoulder": XRBodyTracker.JOINT_RIGHT_SHOULDER,
	"rightUpperArm": XRBodyTracker.JOINT_RIGHT_UPPER_ARM,
	"rightLowerArm": XRBodyTracker.JOINT_RIGHT_LOWER_ARM,
	"rightHand":     XRBodyTracker.JOINT_RIGHT_HAND,
}

const DEFAULT_BINDINGS = {
	#region Camera
	"Brows": [
		{
			"name": "ParamBrowLY",
			"value_range": Vector2(-1, 1),
			"smoothing": 10
		},
		{
			"name": "ParamBrowRY",
			"value_range": Vector2(-1, 1),
			"smoothing": 10
		},
		{
			"name": "ParamBrowLForm",
			"value_range": Vector2(-1, 1),
			"smoothing": 15
		},
		{
			"name": "ParamBrowLForm",
			"value_range": Vector2(-1, 1),
			"smoothing": 15
		}
	],
	"EyeRightX": [
		{
			"name": "ParamEyeBallX",
			"value_range": Vector2(-1, 1),
			"smoothing": 8
		},
	],
	"EyeRightY": [
		{
			"name": "ParamEyeBallY",
			"value_range": Vector2(-1, 1),
			"smoothing": 8
		},
	],
	"EyeOpenLeft": [
		{
			"name": "ParamEyeLOpen",
			"value_range": Vector2(0, 1),
			"smoothing": 10
		},
	],
	"EyeOpenRight": [
		{
			"name": "ParamEyeROpen",
			"value_range": Vector2(0, 1),
			"smoothing": 10
		},
	],
	"MouthSmile": [
		{
			"name": "ParamMouthForm",
			"value_range": Vector2(-1, 1)
		},
		{
			"name": "ParamEyeLSmile",
			"value_range": Vector2(0, 1),
			"smoothing": 10
		},
		{
			"name": "ParamEyeRSmile",
			"value_range": Vector2(0, 1),
			"smoothing": 10
		},
		{
			"name": "ParamCheek",
			"value_range": Vector2(0.5, 1),
			"smoothing": 45
		},
	],
	"MouthOpen": [
		{
			"name": "ParamMouthOpen",
			"value_range": Vector2(0, 2.1),
		},
	],
	"MouthX": [
		{
			"name": "ParamMouthX",
			"value_range": Vector2(-1, 1)
		}
	],
	"TongueOut": [
		{
			"name": "ParamTongue",
			"value_range": Vector2(-1, 1)
		}
	],
	#endregion
	#region Microphone
	"VoiceA": [
		{
			"name": "ParamA",
			"value_range": Vector2(0, 1)
		}
	],
	"VoiceI": [
		{
			"name": "ParamI",
			"value_range": Vector2(0, 1)
		}
	],
	"VoiceU": [
		{
			"name": "ParamU",
			"value_range": Vector2(0, 1)
		}
	],
	"VoiceE": [
		{
			"name": "ParamE",
			"value_range": Vector2(0, 1)
		}
	],
	"VoiceO": [
		{
			"name": "ParamO",
			"value_range": Vector2(0, 1)
		}
	],
	"VoiceSilence": [
		{
			"name": "ParamSilence",
			"value_range": Vector2(0, 1)
		}
	]
	#endregion
}

const spacing = 30

func id() -> StringName:
	return "vrm"
	
## given a VRM model, create a blueprint using standard blendshape mapping
func load_graph(model: VtModel, path = "") -> Array[Blueprint]:
	if model.modelmeta.format != preload("res://lib/model/formats/vrm/model_loader.gd").new().model_format():
		return []
	
	var graph = BlueprintTemplate.instantiate()
	graph.name = "VRM Standard"
	
	var blink = graph.spawn_action(&"blink", model)
	var input = graph.spawn_action(&"tracking_input", model, {
		"kind": &"iOSBlendShape"
	})
	
	var output: VtAction = graph.spawn_action(&"model_output", model)
	
	blink.position_offset = Vector2(-500, 250)
	
	var x = 500
	var y = 0
	for input_parameter in DEFAULT_BINDINGS:
		var input_slot = input.get_output_port_by_name(input_parameter)
		if input_slot < 0:
			continue
			
		var input_range = Registry.get(input_parameter).range
		
		for output_parameter in DEFAULT_BINDINGS[input_parameter]:
			var _x = x
			var _y = 0
			var _input = input
			var _input_slot = input_slot
			var output_slot = output.get_input_port_by_name(output_parameter.name)
			if output_slot < 0:
				continue
				
			var output_range = model.get("parameters/%s/range" % output_parameter.name)
			var map_range = output_parameter.get("value_range", output_range)
			
			if output_parameter.get("smoothing", 0) > 0:
				var smoothing = graph.spawn_action(&"smoothing", model)
				
				smoothing.smoothing = output_parameter.get("smoothing", 0) / 100.0
				graph._on_connection_request(
					_input.name, _input_slot, smoothing.name, 0
				)
				smoothing.position_offset = Vector2(_x, y)
				_input = smoothing
				_input_slot = 0
				_x += smoothing.size.x + 96
				_y = max(smoothing.size.y + 96, _y)
				
			if input_range.x != map_range.x or map_range.x != output_range.x or \
			   input_range.y != map_range.y or map_range.y != output_range.y:
				var rangemap = graph.spawn_action(&"rangemap", model, {
					"a": input_range,
					"b": map_range,
				})
				graph._on_connection_request(
					_input.name, _input_slot,
					rangemap.name, rangemap.get_input_port_by_name("value")
				)
				rangemap.position_offset = Vector2(_x, y)
				_input = rangemap
				_input_slot = rangemap.get_output_port_by_name("value")
				_x += rangemap.size.x + 96
				_y = max(rangemap.size.y + 96, _y)
				
			y += _y
			
			graph._on_connection_request(
				_input.name, _input_slot, output.name, output_slot
			)
			
			if _x > output.position_offset.x:
				output.position_offset.x = _x
			
	output.position_offset.x += 250

	return [
		graph
	]
