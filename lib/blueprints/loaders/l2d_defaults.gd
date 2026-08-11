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
			# Cubism standard id; some older models use ParamMouthOpen
			"name": "ParamMouthOpenY",
			"value_range": Vector2(0, 1),
			"smoothing": 10
		},
		{
			"name": "ParamMouthOpen",
			"value_range": Vector2(0, 1),
			"smoothing": 10
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

const PAD = 30

func id() -> StringName:
	return "l2d"

## given a L2D model, create a blueprint using the standard parameter list
## https://docs.live2d.com/en/cubism-editor-manual/standard-parameter-list/
func load_graph(model: VtModel) -> Array[Blueprint]:
	if model.modelmeta == null or model.modelmeta.format != "l2d":
		return []

	var model_params := model.get_parameters()
	if model_params.is_empty():
		return []

	# tracking_input ports come from Registry groups; ensure Camera exists even
	# if FaceTracker hasn't been activated yet (model can load before settings).
	_ensure_camera_registry()

	var graph: Blueprint = BlueprintTemplate.instantiate()
	graph.name = "L2D Standard"
	add_child(graph)

	var breathe: VtAction = graph.spawn_action(&"breathe", model)
	var blink: VtAction = graph.spawn_action(&"blink", model)
	var camera_tracker: VtAction = graph.spawn_action(&"tracking_input", model)
	var mic_tracker: VtAction = graph.spawn_action(&"tracking_input", model)
	var model_output: VtAction = graph.spawn_action(&"model_output", model)

	if camera_tracker == null or mic_tracker == null or model_output == null:
		push_error("l2d defaults: failed to spawn required blueprint actions")
		remove_child(graph)
		graph.free()
		return []

	camera_tracker.name = "CameraTracker"
	camera_tracker.kind = &"Camera"
	mic_tracker.name = "MicrophoneTracker"
	mic_tracker.kind = &"Microphone"

	var tracker_bound := {
		camera_tracker: false,
		mic_tracker: false,
		breathe: false,
		blink: false,
	}

	var x := maxf(camera_tracker.size.x, mic_tracker.size.x) + PAD
	var y := 0.0
	var column_width := 0.0
	var connected := 0

	for input_parameter in DEFAULT_BINDINGS:
		for output_parameter in DEFAULT_BINDINGS[input_parameter]:
			var out_name := String(output_parameter.name)
			if not _model_has_parameter(model_params, out_name):
				continue

			var input: VtAction = null
			var input_slot := -1
			for t in [camera_tracker, mic_tracker]:
				input_slot = t.get_output_port_by_name(StringName(input_parameter))
				if input_slot != -1:
					input = t
					tracker_bound[t] = true
					break
			if input == null or input_slot < 0:
				continue

			var output_slot: int = model_output.get_input_port_by_name(StringName(out_name))
			if output_slot < 0:
				continue

			var _x := x
			if float(output_parameter.get("smoothing", 0.0)) > 0.0:
				var smoothing: VtAction = graph.spawn_action(&"smoothing", model)
				if smoothing == null:
					continue
				smoothing.smoothing = float(output_parameter.get("smoothing", 0.0)) / 100.0
				graph._on_connection_request(
					input.name, input_slot,
					smoothing.name, smoothing.get_input_port_by_name("value")
				)
				smoothing.position_offset = Vector2(_x, y)
				_x += smoothing.size.x + PAD
				input = smoothing
				input_slot = smoothing.get_output_port_by_name("value")

			graph._on_connection_request(
				input.name, input_slot,
				model_output.name, output_slot
			)
			connected += 1
			y += PAD * 2
			column_width = maxf(column_width, _x)

	if connected == 0:
		push_warning(
			"l2d defaults: no parameter bindings connected for %s (missing model params or tracking registry)"
			% model.modelmeta.name
		)
	else:
		print_debug("l2d defaults: connected %d bindings for %s" % [connected, model.modelmeta.name])

	x += column_width
	model_output.position_offset = Vector2(x, 0)

	# Dynamic tracker/output sizes settle after one frame.
	await get_tree().process_frame

	y = 0.0
	for t in tracker_bound:
		# Keep camera/mic trackers even if unbound so the graph remains editable.
		if tracker_bound[t] == false and t in [breathe, blink]:
			if is_instance_valid(t):
				t.queue_free()
			continue
		t.position_offset = Vector2(0, y)
		y += t.size.y + PAD

	remove_child(graph)
	return [graph]

func _model_has_parameter(model_params: Dictionary, param_name: String) -> bool:
	return model_params.has(param_name) or model_params.has(StringName(param_name))

func _ensure_camera_registry() -> void:
	if Registry["FaceAngleX"] != null:
		return
	# Subset used by DEFAULT_BINDINGS; full set is registered when a camera tracker starts.
	Registry.add_parameter("FaceAngleX", Vector2(-30, 30))
	Registry.add_parameter("FaceAngleY", Vector2(-30, 30))
	Registry.add_parameter("FaceAngleZ", Vector2(-30, 30))
	Registry.add_parameter("MouthSmile", Vector2(0, 1))
	Registry.add_parameter("MouthOpen", Vector2(0, 1))
	Registry.add_parameter("Brows", Vector2(0, 1))
	Registry.add_parameter("TongueOut", Vector2(0, 1))
	Registry.add_parameter("EyeOpenLeft", Vector2(0, 1), 1)
	Registry.add_parameter("EyeOpenRight", Vector2(0, 1), 1)
	Registry.add_parameter("EyeLeftX", Vector2(-1, 1))
	Registry.add_parameter("EyeLeftY", Vector2(-1, 1))
	Registry.add_parameter("EyeRightX", Vector2(-1, 1))
	Registry.add_parameter("EyeRightY", Vector2(-1, 1))
	Registry.add_parameter("MouthX", Vector2(-1, 1))
