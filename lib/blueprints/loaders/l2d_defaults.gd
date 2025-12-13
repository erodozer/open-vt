extends "./blueprint_loader.gd"

const DEFAULT_BINDINGS = {
	#region Camera
	"FaceAngleX": [
		{
			"name": "ParamAngleX",
			"value_range": Vector2(-30, 30),
			"smoothing": 15
		},
		{
			"name": "ParamBodyAngleX",
			"value_range": Vector2(-10, 10),
			"smoothing": 20
		},
		{
			"name": "ParamStep",
			"value_range": Vector2(-10, 10),
			"smoothing": 10
		},
	],
	"FaceAngleY": [
		{
			"name": "ParamAngleY",
			"value_range": Vector2(-30, 30),
			"smoothing": 15
		},
		{
			"name": "ParamBodyAngleY",
			"value_range": Vector2(-10, 10),
			"smoothing": 20
		}
	],
	"FaceAngleZ": [
		{
			"name": "ParamAngleZ",
			"value_range": Vector2(-30, 30),
			"smoothing": 30
		},
		{
			"name": "ParamBodyAngleZ",
			"value_range": Vector2(-10, 10),
			"smoothing": 20
		}
	],
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

## given a L2D model, create a blueprint using the standard parameter list
## https://docs.live2d.com/en/cubism-editor-manual/standard-parameter-list/
func load_graph(model: VtModel) -> Array[Blueprint]:
	var graph = BlueprintTemplate.instantiate()
	graph.name = "L2D Standard"
	
	var breathe = graph.spawn_action(&"breathe", model)
	var blink = graph.spawn_action(&"blink", model)
	
	breathe.position_offset = Vector2(-500, 0)
	blink.position_offset = Vector2(-500, 250)
	
	var column_width = 0
	var x = 0
	var y = 0
	for input_parameter in DEFAULT_BINDINGS:
		for output_parameter in DEFAULT_BINDINGS[input_parameter]:
			if StringName(output_parameter.name) not in model.parameters:
				continue
			
			var input = graph.spawn_action(&"tracking_parameter", model)
			var output = graph.spawn_action(&"model_parameter", model)
			var _x = x
		 
			input.parameter = input_parameter
			input.clamp_range = Registry[input_parameter].range
			output.parameter = model.parameters.keys().find(output_parameter.name)
			output.clamp_range = output_parameter.value_range
			input.position_offset = Vector2(x, y)
			_x += input.size.x + spacing
		
			if output_parameter.get("smoothing", 0) > 0:
				var smoothing = graph.spawn_action(&"smoothing", model)
				
				smoothing.smoothing = output_parameter.get("smoothing", 0) / 100.0
				graph._on_connection_request(
					input.name, 0, smoothing.name, 0
				)
				smoothing.position_offset = Vector2(_x, y)
				_x += smoothing.size.x + spacing
				input = smoothing
			
			if input != null:
				graph._on_connection_request(
					input.name, 0, output.name, 0
				)
			
			output.position_offset = Vector2(_x, y)
			y += output.size.y + 96
			_x += output.size.x + 120
				
			column_width = max(column_width, _x + 200)
				
			if y > 2000:
				x += column_width - x
				y = 0
				column_width = 0
	return [
		graph
	]
