extends Window

const Files = preload("res://lib/utils/files.gd")
const VtModel = preload("res://lib/model/vt_model.gd")
const VtItem = preload("res://lib/items/vt_item.gd")
const VtAction = preload("./graph/vt_action.gd")

const ActionGraph = preload("res://studio/action_engine/action_graph.tscn")
const Stage = preload("res://studio/stage/stage.gd")

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
	get_tree().get_first_node_in_group(Stage.GROUP_NAME).model_changed.connect(_on_stage_model_changed)
	get_tree().get_first_node_in_group(Stage.GROUP_NAME).item_added.connect(_on_stage_item_added)

func _on_add_hotkey_pressed(model: VtModel, node: VtAction, graph: GraphEdit = active_graph) -> VtAction:
	node.model = model
	graph.add_child(node)
	node.position_offset = (graph.scroll_offset + graph.size / 2) / graph.zoom - node.size / 2
	return node

func _on_stage_model_changed(model: VtModel) -> void:
	for i in %Profiles.get_children():
		i.queue_free()
	
	%ProfileTabs.clear_tabs()
	
	await get_tree().process_frame
	
	var graphs = []
	if FileAccess.file_exists(model.model.openvt_parameters):
		graphs = _load_graph(model)
	if not graphs and FileAccess.file_exists(model.model.studio_parameters):
		graphs = _load_from_vts(model)
	for g in graphs:
		%Profiles.add_child(g)
	%ProfileTabs.current_tab = 0
	
func _on_stage_item_added(item: VtItem) -> void:
	if item.item_type != VtItem.ItemType.MODEL:
		return
		
	var model = item.get_node("Render") as VtModel
	var graphs = []
	if FileAccess.file_exists(model.model.openvt_parameters):
		graphs = _load_graph(model)
	if not graphs and FileAccess.file_exists(model.model.studio_parameters):
		graphs = _load_from_vts(model)
		
	for g in graphs:
		g.visible = false
		item.add_child(g) # item graphs, do that by opening as a model
	
func _load_graph(model: VtModel) -> Array:
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
		graph.deserialize(model, graphs[profile], %Palette)
		remove_child(graph)
		if graph.get_child_count() > 0:
			valid_graphs.append(graph)
	
	return valid_graphs

## adapts bindings from VTS into our action graph
func _load_from_vts(model: VtModel) -> Array:
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
			keybind = _on_add_hotkey_pressed(model, preload("./graph/inputs/hotkey_action.tscn").instantiate(), graph)
			var binding = keybind.get_node("%Handler")
			binding.load_from_vts(hotkey)
			keybind.get_node("%Input").text = " + ".join(binding.input_as_list)
			keybind.position_offset = Vector2(x, y)
		if hotkey.Triggers.get("ScreenButton", 0) > 0:
			btnbind = _on_add_hotkey_pressed(model, preload("./graph/inputs/screen_button.tscn").instantiate(), graph)
			btnbind.get_node("%Mapping").get_child(hotkey.Triggers.ScreenButton - 1).button_pressed = true
			if keybind != null:
				btnbind.position_offset = Vector2(x, y + keybind.size.y + spacing)
			else:
				btnbind.position_offset = Vector2(x, y)
		
		var output: GraphNode
		match hotkey.Action:
			"TriggerAnimation":
				output = _on_add_hotkey_pressed(model, preload("./graph/outputs/play_animation.tscn").instantiate(), graph)
				
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
				output = _on_add_hotkey_pressed(model, preload("./graph/outputs/toggle_expression.tscn").instantiate(), graph)
				
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
	
	var breathe = _on_add_hotkey_pressed(model, preload("./graph/logic/breathe.tscn").instantiate(), graph)
	var blink = _on_add_hotkey_pressed(model, preload("./graph/logic/blink.tscn").instantiate(), graph)
	
	breathe.position_offset = Vector2(-500, 0)
	blink.position_offset = Vector2(-500, 250)
	
	var column_width = 800
	for data in vtube_data["ParameterSettings"]:
		var input = _on_add_hotkey_pressed(model, preload("./graph/inputs/tracking_parameter.tscn").instantiate(), graph)
		var output = _on_add_hotkey_pressed(model, preload("./graph/outputs/model_parameter.tscn").instantiate(), graph)
		
		input.load_from_vts(data)
		output.load_from_vts(data)
		
		input.position_offset = Vector2(x, y)
		
		var unbound = input.parameter == "unset"
		var breathing = data.get("UseBreathing", false)
		var blinking = data.get("UseBlinking", false)
		var _x = x
		if (breathing or blinking) and unbound:
			input.queue_free()
		else:
			_x += input.size.x + 40
		
		if breathing:
			var scalar = _on_add_hotkey_pressed(model, preload("./graph/logic/arithmetic.tscn").instantiate(), graph)
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
			var scalar = _on_add_hotkey_pressed(model, preload("./graph/logic/arithmetic.tscn").instantiate(), graph)
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
	remove_child(graph)
	graphs.append(graph)
			
#endregion
	return graphs
	
func save_settings(model_data: Dictionary):
	var graphs = model_data.get("graphs", {})
	
	for i in %Profiles.get_children():
		graphs[i.name] = i.serialize()
		
	model_data["graphs"] = graphs
	
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
	if tab >= %Profiles.get_tab_count():
		return
	%ProfileName.text = %Profiles.get_child(tab).name
	%Profiles.current_tab = tab
	%ProfileEnabled.set_pressed_no_signal(
		%Profiles.get_child(tab).process_mode != PROCESS_MODE_DISABLED
	)

func _on_profile_enabled_toggled(toggled_on: bool) -> void:
	active_graph.process_mode = PROCESS_MODE_INHERIT if toggled_on else PROCESS_MODE_DISABLED

func _on_delete_profile_pressed() -> void:
	var graph = active_graph
	var idx = active_profile
	var popup = ConfirmationDialog.new()
	popup.dialog_text = "Delete Profile %s\nThis action is Permanent" % active_graph.name
	popup.cancel_button_text = "Nevermind"
	popup.ok_button_text = "Yes, Delete It"
	popup.confirmed.connect(
		func ():
			graph.queue_free()
			popup.queue_free()
			await get_tree().process_frame
			_on_profile_tabs_tab_selected(0)
	)
	add_child(popup)
	popup.popup_centered()
