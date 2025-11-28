extends "./blueprint_loader.gd"

const spacing = 30
	
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
			_y += keybind.size.y + spacing
			_x = keybind.size.x + spacing
		if hotkey.Triggers.get("ScreenButton", 0) > 0:
			btnbind = graph.spawn_action(&"screen_button", model)
			btnbind.get_node("%Mapping").get_child(hotkey.Triggers.ScreenButton - 1).button_pressed = true
			btnbind.position_offset = Vector2(x, y + _y)
			_y += btnbind.size.y + spacing
			_x = max(_x, btnbind.size.x + spacing)
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
				_x += output.size.x + spacing
				_y = max(_y, output.size.y + spacing)
				
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
					output.expression = e_name
				output.get_node("%Fade/Value").value = duration
				output.position_offset = Vector2(x + _x, y)
				_x += output.size.x + spacing
				_y = max(_y, output.size.y + spacing)
				
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
	
	var breathe = graph.spawn_action(&"breathe", model)
	var blink = graph.spawn_action(&"blink", model)
	
	breathe.position_offset = Vector2(-500, 0)
	blink.position_offset = Vector2(-500, 250)
	
	var column_width = 0
	var x = 0
	var y = 0
	for data in vtube_data["ParameterSettings"]:
		var input = graph.spawn_action(&"tracking_parameter", model)
		var output = graph.spawn_action(&"model_parameter", model)
		
		input.load_from_vts(data)
		output.load_from_vts(data)
		
		input.position_offset = Vector2(x, y)
		
		var unbound = input.parameter == "unset"
		var breathing = data.get("UseBreathing", false)
		var blinking = data.get("UseBlinking", false)
		var _x = x
		if breathing or unbound:
			input.queue_free()
			input = null
		else:
			_x += input.size.x + spacing
		
		# VTS's breathe behavior overrides any input parameter setting
		if breathing:
			input = breathe
			
		if blinking:
			var scalar = graph.spawn_action(&"arithmetic", model)
			scalar.operator = 1
			if breathing or not unbound:
				graph._on_connection_request(
					input.name, 0, scalar.name, 0
				)
				graph._on_connection_request(
					blink.name, 0, scalar.name, 1
				)
				scalar.position_offset = Vector2(_x, y)
				_x += scalar.size.x + spacing
				input = scalar
			else:
				scalar.queue_free()
				input = blink
			
		if float(data.get("Smoothing", 0.0)) > 0.0:
			var smoothing = graph.spawn_action(&"smoothing", model)
			smoothing.smoothing = data.get("Smoothing", 0.0) / 100.0
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
	return graph
	
## adapts bindings from VTS into our action graph
func load_graph(model: VtModel) -> Array[Blueprint]:
	# load vts hotkey settings
	var vtube_data = Files.read_json(model.model.studio_parameters)
	
	return [
		_build_hotkey_graph(model, vtube_data),
		_build_parameter_graph(model, vtube_data)
	]
