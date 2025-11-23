extends Node

const Files = preload("res://lib/utils/files.gd")
const VtModel = preload("res://lib/model/vt_model.gd")
const VtItem = preload("res://lib/items/vt_item.gd")
const VtAction = preload("./graph/vt_action.gd")

const ActionGraph = preload("res://studio/action_engine/action_graph.tscn")
const Stage = preload("res://studio/stage/stage.gd")

const GRAPH_NODES_DIR = "res://studio/action_engine/graph"
static var INPUTS_DIR = GRAPH_NODES_DIR.path_join("inputs")
static var OUTPUTS_DIR = GRAPH_NODES_DIR.path_join("outputs")

var _action_types: Array[VtAction] = [
	preload("./graph/inputs/hotkey_action.tscn").instantiate(),
	preload("./graph/inputs/screen_button.tscn").instantiate(),
	preload("./graph/inputs/tracking_parameter.tscn").instantiate(),
	preload("res://studio/action_engine/graph/logic/arithmetic.tscn").instantiate(),
	preload("res://studio/action_engine/graph/logic/blink.tscn").instantiate(),
	preload("res://studio/action_engine/graph/logic/breathe.tscn").instantiate(),
	preload("res://studio/action_engine/graph/logic/smoothing.tscn").instantiate(),
	preload("res://studio/action_engine/graph/outputs/model_parameter.tscn").instantiate(),
	preload("res://studio/action_engine/graph/outputs/play_animation.tscn").instantiate(),
	preload("res://studio/action_engine/graph/outputs/toggle_expression.tscn").instantiate()
]

var _mapping: Dictionary = _action_types.reduce(
	func (acc, action: VtAction):
		acc[action.get_type()] = action
		return acc,
	{}
)

func create_action(type: StringName):
	return _mapping[type].instantiate()
	
func load_graph(model: VtModel) -> Array:
	var graphs = []
	if FileAccess.file_exists(model.model.openvt_parameters):
		graphs = _load_ovt_graph(model)
	if not graphs and FileAccess.file_exists(model.model.studio_parameters):
		graphs = _load_vts_graph(model)
	return graphs
	
func spawn_action(node: VtAction, graph: GraphEdit, model: VtModel) -> VtAction:
	node.model = model
	graph.add_child(node)
	node.position_offset = (graph.scroll_offset + graph.size / 2) / graph.zoom - node.size / 2
	return node
	
func _load_ovt_graph(model: VtModel) -> Array:
	var ovt_data: Dictionary = Files.read_json(model.model.openvt_parameters)
	if ovt_data.is_empty():
		return []
		
	var graphs: Dictionary = ovt_data.get("graphs", {})
	if graphs.is_empty():
		return []
	
	var valid_graphs = []
	for profile in graphs:
		var graph = ActionGraph.instantiate()
		graph.name = profile
		add_child(graph)
		graph.deserialize(model, graphs[profile], _mapping)
		remove_child(graph)
		if graph.get_child_count() > 0:
			valid_graphs.append(graph)
	
	return valid_graphs
	
## adapts bindings from VTS into our action graph
func _load_vts_graph(model: VtModel) -> Array:
	const spacing = 30
	# load vts hotkey settings
	var vtube_data = Files.read_json(model.model.studio_parameters)
	var y = 0
	var x = 0
	
	var graphs = []
#region hotkey binding
	var graph = preload("./action_graph.tscn").instantiate()
	graph.name = "VTS_Hotkeys"
	add_child(graph)
	
	for hotkey in vtube_data.get("Hotkeys", []):
		var keybind: VtAction
		var btnbind: VtAction
		if ["","",""] != [hotkey.Triggers.Trigger1, hotkey.Triggers.Trigger2, hotkey.Triggers.Trigger3]:
			keybind = spawn_action(preload("./graph/inputs/hotkey_action.tscn").instantiate(), graph, model)
			var binding = keybind.get_node("%Handler")
			binding.load_from_vts(hotkey)
			keybind.get_node("%Input").text = " + ".join(binding.input_as_list)
			keybind.position_offset = Vector2(x, y)
		if hotkey.Triggers.get("ScreenButton", 0) > 0:
			btnbind = spawn_action(preload("./graph/inputs/screen_button.tscn").instantiate(), graph, model)
			btnbind.get_node("%Mapping").get_child(hotkey.Triggers.ScreenButton - 1).button_pressed = true
			if keybind != null:
				btnbind.position_offset = Vector2(x, y + keybind.size.y + spacing)
			else:
				btnbind.position_offset = Vector2(x, y)
		
		var output: GraphNode
		match hotkey.Action:
			"TriggerAnimation":
				output = spawn_action(preload("./graph/outputs/play_animation.tscn").instantiate(), graph, model)
				
				var anim_name = hotkey.File
				var duration = hotkey.FadeSecondsAmount * 1000.0
				var animations = model.motions
				for i in range(len(animations)):
					var a = animations[i]
					if a == anim_name:
						output.get_node("%Animation").select(i)
				output.position_offset = Vector2(x + 280, y)
				output.get_node("%Fade/Value").value = duration
				
				# pressed
				if keybind != null:
					graph._on_connection_request(
						keybind.name, 0, output.name, 2
					)
					
					# released
					if hotkey.DeactivateAfterKeyUp:
						graph._on_connection_request(
							keybind.name, 1, output.name, 3
						)
				
				if btnbind != null:
					graph._on_connection_request(
						btnbind.name, 0, output.name, 2
					)
			"ToggleExpression", "RemoveAllExpressions":
				output = spawn_action(preload("./graph/outputs/toggle_expression.tscn").instantiate(), graph, model)
				
				var e_name: String = hotkey.File
				var duration = hotkey.FadeSecondsAmount * 1000.0
				if hotkey.Action == "ToggleExpression":
					var animations = model.expressions
					for i in range(len(animations)):
						var a = animations[i]
						if a == e_name:
							output.get_node("%Expression").select(i + 1)
				output.get_node("%Fade/Value").value = duration
				output.position_offset = Vector2(x + 280, y)
				
				if keybind != null:
					if hotkey.DeactivateAfterKeyUp:
						graph._on_connection_request(
							keybind.name, 0, output.name, 2
						)
						graph._on_connection_request(
							keybind.name, 1, output.name, 3
						)
					else:
						graph._on_connection_request(
							keybind.name, 0, output.name, 1
						)
				if btnbind != null:
					graph._on_connection_request(
						btnbind.name, 0, output.name, 1
					)
		
		if output and btnbind:
			y += max(output.size.y, btnbind.position_offset.y - y + btnbind.size.y) + spacing
		elif output and keybind:
			y += max(output.size.y, keybind.size.y) + spacing
		elif output:
			y += output.size.y + spacing
		elif btnbind:
			y = btnbind.position_offset.y + btnbind.size.y + spacing
		elif keybind:
			y += keybind.size.y + spacing
			
		if y > 2000:
			x += 800
			y = 0
	remove_child(graph)
	graphs.append(graph)
#endregion

#region parameter binding
	graph = preload("./action_graph.tscn").instantiate()
	graph.name = "VTS_Parameters"
	
	add_child(graph)
	
	var breathe = spawn_action(preload("./graph/logic/breathe.tscn").instantiate(), graph, model)
	var blink = spawn_action(preload("./graph/logic/blink.tscn").instantiate(), graph, model)
	
	breathe.position_offset = Vector2(-500, 0)
	blink.position_offset = Vector2(-500, 250)
	
	var column_width = 0
	x = 0
	y = 0
	for data in vtube_data["ParameterSettings"]:
		var input = spawn_action(preload("./graph/inputs/tracking_parameter.tscn").instantiate(), graph, model)
		var output = spawn_action(preload("./graph/outputs/model_parameter.tscn").instantiate(), graph, model)
		
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
			_x += input.size.x + 40
		
		# VTS's breathe behavior overrides any input parameter setting
		if breathing:
			input = breathe
			
		if blinking:
			var scalar = spawn_action(preload("./graph/logic/arithmetic.tscn").instantiate(), graph, model)
			scalar.operator = 1
			if breathing or not unbound:
				graph._on_connection_request(
					input.name, 0, scalar.name, 0
				)
				graph._on_connection_request(
					blink.name, 0, scalar.name, 1
				)
				scalar.position_offset = Vector2(_x, y)
				_x += scalar.size.x + 40
				input = scalar
			else:
				scalar.queue_free()
				input = blink
			
		if float(data.get("Smoothing", 0.0)) > 0.0:
			var smoothing = spawn_action(preload("res://studio/action_engine/graph/logic/smoothing.tscn").instantiate(), graph, model)
			smoothing.smoothing = data.get("Smoothing", 0.0) / 100.0
			graph._on_connection_request(
				input.name, 0, smoothing.name, 0
			)
			smoothing.position_offset = Vector2(_x, y)
			_x += smoothing.size.x + 40
			input = smoothing
		
		if input != null:
			graph._on_connection_request(
				input.name, 0, output.name, 0
			)
		
		output.position_offset = Vector2(_x, y)
		y += output.size.y + 96
		_x += output.size.x + 120
			
		column_width = max(column_width, _x)
			
		if y > 2000:
			x += column_width - x
			y = 0
			column_width = 0
	remove_child(graph)
	graphs.append(graph)
			
#endregion
	return graphs
