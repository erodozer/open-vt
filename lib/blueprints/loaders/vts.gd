extends "./blueprint_loader.gd"
	
const PAD = 64
	
func id() -> StringName:
	return "vts"
	
func _build_hotkey_graph(model: VtModel, vtube_data: Dictionary) -> Blueprint:
	var graph = BlueprintTemplate.instantiate()
	graph.name = "VTS_Hotkeys"
	add_child(graph)

	var x = 0
	var y = 0
	var column_width = 0
	
	for hotkey in vtube_data.get("Hotkeys", []):
		var keybind: VtAction
		var btnbind: VtAction
		var _x = 0
		var _y = 0
		if ["","",""] != [hotkey.Triggers.Trigger1, hotkey.Triggers.Trigger2, hotkey.Triggers.Trigger3]:
			keybind = graph.spawn_action(&"hotkey", model)
			var binding = keybind.get_node("%Handler")
			binding.load_from_vts(hotkey)
			keybind.get_node("%Input").text = " + ".join(binding.input_as_list)
			keybind.position_offset = Vector2(x, y + _y)
			_y += keybind.size.y + PAD
			_x = keybind.size.x + PAD
		if hotkey.Triggers.get("ScreenButton", 0) > 0:
			btnbind = graph.spawn_action(&"screen_button", model)
			btnbind.get_node("%Mapping").get_child(hotkey.Triggers.ScreenButton - 1).button_pressed = true
			btnbind.position_offset = Vector2(x, y + _y)
			_y += btnbind.size.y + PAD
			_x = max(_x, btnbind.size.x + PAD)
		if keybind == null and btnbind == null:
			continue
		
		var output: GraphNode
		match hotkey.Action:
			"TriggerAnimation":
				output = graph.spawn_action(&"animation", model)
				
				var anim_name = hotkey.File
				var duration = hotkey.FadeSecondsAmount * 1000.0
				var animations = model.motions
				for i in range(len(animations)):
					var a = animations[i]
					if a == anim_name:
						output.get_node("%Animation").select(i)
				output.position_offset = Vector2(x + _x, y)
				output.get_node("%Fade/Value").value = duration
				_x += output.size.x + PAD
				_y = max(_y, output.size.y + PAD)
				
				# pressed
				if keybind != null:
					graph._on_connection_request(
						keybind.name, 0, output.name, 0
					)
					
					# released
					if hotkey.DeactivateAfterKeyUp:
						graph._on_connection_request(
							keybind.name, 1, output.name, 1
						)
				
				if btnbind != null:
					graph._on_connection_request(
						btnbind.name, 0, output.name, 0
					)
			"ToggleExpression", "RemoveAllExpressions":
				output = graph.spawn_action(&"expression", model)
				
				var e_name: String = hotkey.File
				var duration = hotkey.FadeSecondsAmount * 1000.0
				if hotkey.Action == "ToggleExpression":
					output.expression = e_name.trim_suffix(".exp3.json")
				output.get_node("%Fade/Value").value = duration
				output.position_offset = Vector2(x + _x, y)
				_x += output.size.x + PAD
				_y = max(_y, output.size.y + PAD)
				
				if keybind != null:
					if hotkey.DeactivateAfterKeyUp:
						graph._on_connection_request(
							keybind.name, 0, output.name, 1
						)
						graph._on_connection_request(
							keybind.name, 1, output.name, 2
						)
					else:
						graph._on_connection_request(
							keybind.name, 0, output.name, 0
						)
				if btnbind != null:
					graph._on_connection_request(
						btnbind.name, 0, output.name, 0
					)
		
		y += _y
		column_width = max(_x, column_width)
		if y > 2000:
			x += column_width
			y = 0
			column_width = 0
	remove_child(graph)
	return graph

func _build_parameter_graph(model: VtModel, vtube_data: Dictionary) -> Blueprint:
	
	var graph = BlueprintTemplate.instantiate()
	graph.name = "VTS_Parameters"
	add_child(graph)
	
	var breathe: VtAction = graph.spawn_action(&"breathe", model)
	var blink: VtAction = graph.spawn_action(&"blink", model)
	var camera_tracker: VtAction = graph.spawn_action(&"tracking_input", model, {
		"kind": &"Camera"
	})
	camera_tracker.name = "CameraTracker"
	var mic_tracker: VtAction = graph.spawn_action(&"tracking_input", model, {
		"kind": &"Microphone"
	})
	mic_tracker.name = "MicrophoneTracker"
	var gamepad_tracker: VtAction = graph.spawn_action(&"tracking_input", model, {
		"kind": &"Gamepad"
	})
	gamepad_tracker.name = "GamepadTracker"
	var kbm_tracker: VtAction = graph.spawn_action(&"tracking_input", model, {
		"kind": &"KBM"
	})
	kbm_tracker.name = "KbmTracker"
	
	var tracker_bound = {
		camera_tracker: false,
		mic_tracker: false,
		gamepad_tracker: false,
		kbm_tracker: false,
		breathe: false,
		blink: false
	}
	
	var model_output: VtAction = graph.spawn_action(&"model_output", model)
	
	var column_width = 0
	var x = max(
		camera_tracker.size.x,
		mic_tracker.size.x,
		gamepad_tracker.size.x
	) + PAD
	var y = 0
	for data in vtube_data["ParameterSettings"]:
		var input_binding = data.get("Input", "unset")
		var input: VtAction
		var input_slot: int
		var input_range: Vector2 = Vector2.ZERO
		for t in [camera_tracker, mic_tracker, kbm_tracker, gamepad_tracker]:
			input = t
			input_slot = t.get_output_port_by_name(input_binding)
			if input_slot != -1:
				tracker_bound[t] = true
				input_range = Registry.get(input_binding).range
				break

		var output = model_output
		var output_slot: int = model_output.get_input_port_by_name(data.OutputLive2D)
		if output_slot == -1: # paramter no longer exists on the model for some reason
			continue
		
		var output_range: Vector2 = model.get("parameters/%s/range" % data.OutputLive2D)
		
		var unbound = input_slot < 0
		var breathing = data.get("UseBreathing", false)
		var blinking = data.get("UseBlinking", false)
		var _x = x
		var _y = 0
		
		# VTS's breathe behavior overrides any input parameter setting
		if breathing:
			tracker_bound[breathe] = true
			input = breathe
			input_slot = breathe.get_output_port_by_name("value")
			_y = max(_y, input.size.y)
			
		if blinking:
			tracker_bound[blink] = true
			var scalar: VtAction = graph.spawn_action(&"arithmetic", model)
			scalar.operator = 1
			if breathing or not unbound:
				graph._on_connection_request(
					input.name, input_slot, 
					scalar.name, scalar.get_input_port_by_name("a")
				)
				graph._on_connection_request(
					blink.name, blink.get_output_port_by_name("value"),
					scalar.name, scalar.get_input_port_by_name("b")
				)
				scalar.position_offset = Vector2(_x, y)
				input = scalar
			else:
				scalar.queue_free()
				input = blink
				input_slot = blink.get_output_port_by_name("value")
			_y = max(_y, scalar.size.y + PAD)
			_x += scalar.size.x + PAD
			
		if float(data.get("Smoothing", 0.0)) > 0.0 and input != null:
			var smoothing: VtAction = graph.spawn_action(&"smoothing", model, {
				"smoothing": data.get("Smoothing", 0.0) / 100.0
			})
			graph._on_connection_request(
				input.name, input_slot,
				smoothing.name, smoothing.get_input_port_by_name("value")
			)
			smoothing.position_offset = Vector2(_x, y)
			_x += smoothing.size.x + PAD
			input = smoothing
			input_slot = smoothing.get_output_port_by_name("value")
			_y = max(_y, smoothing.size.y + PAD)
		
		if not unbound and (
			data.get("InputRangeLower", input_range.x) != input_range.x or \
			data.get("InputRangeUpper", input_range.y) != input_range.y or \
			data.get("OutputRangeLower", input_range.x) != input_range.x or \
			data.get("OutputRangeUpper", input_range.y) != input_range.y or \
			data.get("ClampInput", false) or data.get("ClampOutput", false)
		):
			var remap_input: VtAction = graph.spawn_action(&"rangemap", model, {
				"a": Vector2(
					data.get("InputRangeLower", input_range.x),
					data.get("InputRangeUpper", input_range.y),
				),
				"a_clamp": data.get("ClampInput", false),
				"b": Vector2(
					data.get("OutputRangeLower", output_range.x),
					data.get("OutputRangeUpper", output_range.y),
				),
				"b_clamp": data.get("ClampOutput", false)
			})
			graph._on_connection_request(
				input.name, input_slot,
				remap_input.name, remap_input.get_input_port_by_name("value")
			)
			remap_input.position_offset = Vector2(_x, y)
			_x += remap_input.size.x + PAD
			input = remap_input
			input_slot = remap_input.get_output_port_by_name("value")
			_y = max(_y, remap_input.size.y + PAD)
		
		if input != null:
			graph._on_connection_request(
				input.name, input_slot, output.name, output_slot
			)
		
		y += _y
		column_width = max(column_width, _x)
			
	x += column_width
	model_output.position_offset = Vector2(x, 0)
	
	# rearrange nodes in graph for more readable spacing
	# these node types are known for having dynamic sizes, so we must wait for
	# their real dimensions to be updated before repositioning
	await get_tree().process_frame
	
	y = 0
	for t in tracker_bound:
		if tracker_bound[t] == false:
			t.queue_free()
			continue
		
		t.position_offset = Vector2(0, y)
		y += t.size.y + PAD
	
	remove_child(graph)
	return graph
	
## adapts bindings from VTS into our action graph
func load_graph(model: VtModel) -> Array[Blueprint]:
	# load vts hotkey settings
	if not model.modelmeta.studio_parameters:
		return []
	var vtube_data = Files.read_json(model.modelmeta.studio_parameters)
	
	return [
		await _build_hotkey_graph(model, vtube_data),
		await _build_parameter_graph(model, vtube_data)
	]
