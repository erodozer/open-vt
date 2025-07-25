extends Window

const VtModel = preload("res://lib/model/vt_model.gd")
const VtAction = preload("./graph/vt_action.gd")
const TrackingInput = preload("res://lib/tracking/tracker.gd").Inputs
const TrackingMeta = preload("res://lib/tracking/tracker.gd").Meta

const ActionGraph = preload("res://studio/action_engine/action_graph.tscn")

const GRAPH_NODES_DIR = "res://studio/action_engine/graph"
static var INPUTS_DIR = GRAPH_NODES_DIR.path_join("inputs")
static var OUTPUTS_DIR = GRAPH_NODES_DIR.path_join("outputs")

@onready var screen_controller = get_tree().get_first_node_in_group("system:hotkey")

var active_profile: int :
	get():
		return %ProfileTabs.current_tab

var active_graph: GraphEdit :
	get():
		return %Profiles.get_child(active_profile)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for btn in %Palette.get_children():
		if btn is Button:
			btn.pressed.connect(_on_add_hotkey_pressed.bind(btn.get_meta("action")))
			
	get_tree().get_first_node_in_group("system:stage").model_changed.connect(_on_stage_model_changed)

func _on_add_hotkey_pressed(node: PackedScene, graph: GraphEdit = active_graph) -> GraphNode:
	var input = node.instantiate()
	graph.add_child(input)
	input.position_offset = (graph.scroll_offset + graph.size / 2) / graph.zoom - input.size / 2
	return input

func _on_stage_model_changed(model: VtModel) -> void:
	for i in %Profiles.get_children():
		i.queue_free()
	
	%ProfileTabs.clear_tabs()
	
	#if FileAccess.file_exists(model.model.openvt_parameters):
	#	_load_graph(model)
	if FileAccess.file_exists(model.model.studio_parameters):
		_load_from_vts(model)
	
func _load_graph(model):
	pass

## adapts bindings from VTS into our action graph
func _load_from_vts(model: VtModel):
	const spacing = 30
	# load vts hotkey settings
	var vtube_data = JSON.parse_string(FileAccess.get_file_as_string(model.model.studio_parameters))
	var y = 0
	var x = 0
	
#region hotkey binding
	var graph = preload("./action_graph.tscn").instantiate()
	graph.name = "VTS_Hotkeys"
	%Profiles.add_child(graph)
	
	for hotkey in vtube_data.get("Hotkeys", []):
		var keybind: GraphNode
		var btnbind: GraphNode
		if ["","",""] != [hotkey.Triggers.Trigger1, hotkey.Triggers.Trigger2, hotkey.Triggers.Trigger3]:
			keybind = _on_add_hotkey_pressed(preload("./graph/inputs/hotkey_action.tscn"), graph)
			var binding = keybind.get_node("%Handler")
			binding.load_from_vts(hotkey)
			keybind.get_node("%Input").text = " + ".join(binding.input_as_list)
			keybind.position_offset = Vector2(x, y)
		if hotkey.Triggers.get("ScreenButton", 0) > 0:
			btnbind = _on_add_hotkey_pressed(preload("./graph/inputs/screen_button.tscn"), graph)
			btnbind.get_node("%Mapping").get_child(hotkey.Triggers.ScreenButton - 1).button_pressed = true
			if keybind != null:
				btnbind.position_offset = Vector2(x, y + keybind.size.y + spacing)
			else:
				btnbind.position_offset = Vector2(x, y)
		
		var output: GraphNode
		match hotkey.Action:
			"TriggerAnimation":
				output = _on_add_hotkey_pressed(preload("./graph/outputs/play_animation.tscn"), graph)
				
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
				output = _on_add_hotkey_pressed(preload("./graph/outputs/toggle_expression.tscn"), graph)
				
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
			
	%ProfileTabs.current_tab = 0
#endregion

#region parameter binding
	graph = preload("./action_graph.tscn").instantiate()
	graph.name = "VTS_Parameters"
	%Profiles.add_child(graph)
	
	var breathe = _on_add_hotkey_pressed(preload("./graph/logic/breathe.tscn"), graph)
	var blink = _on_add_hotkey_pressed(preload("./graph/logic/blink.tscn"), graph)
	
	breathe.position_offset = Vector2(-500, 0)
	blink.position_offset = Vector2(-500, 250)
	
	var column_width = 800
	for data in vtube_data["ParameterSettings"]:
		var input = _on_add_hotkey_pressed(preload("./graph/inputs/tracking_parameter.tscn"), graph)
		var output = _on_add_hotkey_pressed(preload("./graph/outputs/model_parameter.tscn"), graph)
		
		input.load_from_vts(data)
		output.load_from_vts(data)
		
		input.position_offset = Vector2(x, y)
		
		var unbound = input.parameter == TrackingInput.UNSET
		var breathing = data.get("UseBreathing", false)
		var blinking = data.get("UseBlinking", false)
		var _x = x
		if (breathing or blinking) and unbound:
			input.queue_free()
		else:
			_x += input.size.x + 40
		
		if breathing:
			var scalar = _on_add_hotkey_pressed(preload("./graph/logic/arithmetic.tscn"), graph)
			scalar.operator = 1
			if not unbound:
				graph._on_connection_request(
					input.name, 0, scalar.name, 0
				)
				graph._on_connection_request(
					breathe.name, 0, scalar.name, 1
				)
				_x += scalar.size / 2
				scalar.position_offset = Vector2(_x, y)
				_x += scalar.size.x + 40
				input = scalar
			else:
				scalar.queue_free()
				input = breathe
			
		if blinking:
			var scalar = _on_add_hotkey_pressed(preload("./graph/logic/arithmetic.tscn"), graph)
			scalar.operator = 1
			if breathing or not unbound:
				graph._on_connection_request(
					input.name, 0, scalar.name, 0
				)
				graph._on_connection_request(
					blink.name, 0, scalar.name, 1
				)
				_x += scalar.size.x / 2
				scalar.position_offset = Vector2(_x, y)
				_x += scalar.size.x + 40
				input = scalar
			else:
				scalar.queue_free()
				input = blink
			
		# smoothing = data["Smoothing"]
		
		graph._on_connection_request(
			input.name, 0, output.name, 0
		)
		
		_x += output.size.x / 2
		output.position_offset = Vector2(_x, y)
		y += output.size.y + 96
		_x += output.size.x + 40
			
		column_width = max(column_width, _x)
			
		if y > 2000:
			x += column_width
			y = 0
			column_width = 800
			
#endregion
	%Profiles.current_tab = 0
	
func _on_profile_name_text_changed(new_text: String) -> void:
	active_graph.name = new_text
	%ProfileTabs.set_tab_title(active_profile, new_text)

func _on_add_profile_pressed() -> void:
	var graph = ActionGraph.instantiate()
	graph.name = "New Profile"
	%Profiles.add_child(graph, true)
	%ProfileTabs.current_tab = %ProfileTabs.tab_count - 1
	
func _on_profiles_child_entered_tree(node: Node) -> void:
	if node is GraphEdit:
		%ProfileTabs.add_tab(node.name)

func _on_profiles_child_exiting_tree(node: Node) -> void:
	if node == null:
		return
		
	if not (node is GraphEdit):
		return
	
	for i in %ProfileTabs.tab_count:
		if %ProfileTabs.get_tab_title(i) == node.name:
			%ProfileTabs.remove_tab(i)
			return

func _on_profile_tabs_tab_selected(tab: int) -> void:
	%ProfileName.text = %Profiles.get_child(tab).name
	%Profiles.current_tab = tab
