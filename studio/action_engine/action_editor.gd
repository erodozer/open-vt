extends "res://lib/popout_panel.gd"

const VtModel = preload("res://lib/model/vt_model.gd")
const VtAction = preload("./graph/vt_action.gd")

const GRAPH_NODES_DIR = "res://studio/action_engine/graph"
static var INPUTS_DIR = GRAPH_NODES_DIR.path_join("inputs")
static var OUTPUTS_DIR = GRAPH_NODES_DIR.path_join("outputs")

var graph_elements: Array[GraphNode] = []

@onready var graph: GraphEdit = %ActionGraph

@onready var screen_controller = get_tree().get_first_node_in_group("system:hotkey")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for btn in %Inputs.get_children():
		btn.pressed.connect(_on_add_hotkey_pressed.bind(btn.get_meta("action")))
			
	for btn in %Outputs.get_children():
		btn.pressed.connect(_on_add_hotkey_pressed.bind(btn.get_meta("action")))
			
	get_tree().get_first_node_in_group("system:stage").model_changed.connect(_on_stage_model_changed)

func _on_add_hotkey_pressed(node: PackedScene) -> GraphNode:
	var input = node.instantiate()
	input.position_offset = size / 2
	graph.add_child(input)
	graph_elements.append(input)
	return input

func _on_stage_model_changed(model: VtModel) -> void:
	for i in graph_elements:
		if i != null:
			i.queue_free()
		
	graph_elements.clear()
	
	_load_from_vts(model)
	
func _load_from_vts(model: VtModel):
	const spacing = 30
	# load vts hotkey settings
	var vtube_data = JSON.parse_string(FileAccess.get_file_as_string(model.model.studio_parameters))
	var y = 0
	var x = 0
	for hotkey in vtube_data.get("Hotkeys", []):
		var keybind: GraphNode
		var btnbind: GraphNode
		var has_input = false
		if ["","",""] != [hotkey.Triggers.Trigger1, hotkey.Triggers.Trigger2, hotkey.Triggers.Trigger3]:
			keybind = _on_add_hotkey_pressed(preload("./graph/inputs/hotkey_action.tscn"))
			var binding = keybind.get_node("%Handler")
			binding.load_from_vts(hotkey)
			keybind.get_node("%Input").text = " + ".join(binding.input_as_list)
			keybind.position_offset = Vector2(x, y)
		if hotkey.Triggers.get("ScreenButton", 0) > 0:
			btnbind = _on_add_hotkey_pressed(preload("./graph/inputs/screen_button.tscn"))
			btnbind.get_node("%Mapping").get_child(hotkey.Triggers.ScreenButton - 1).button_pressed = true
			if keybind != null:
				btnbind.position_offset = Vector2(x, y + keybind.size.y + spacing)
			else:
				btnbind.position_offset = Vector2(x, y)
		
		var output: GraphNode
		match hotkey.Action:
			"TriggerAnimation":
				output = _on_add_hotkey_pressed(preload("./graph/outputs/play_animation.tscn"))
				
				var anim_name = hotkey.File
				var duration = hotkey.FadeSecondsAmount * 1000.0
				var animations = model.motions
				for i in range(len(animations)):
					var a = animations[i]
					if a == anim_name:
						output.get_node("%Animation").select(i)
				output.get_node("%Delay/Value").value = duration
				output.position_offset = Vector2(x + 280, y)
				
				# pressed
				if keybind != null:
					_on_connection_request(
						keybind.name, 0, output.name, 2
					)
					
					# released
					if hotkey.DeactivateAfterKeyUp:
						_on_connection_request(
							keybind.name, 1, output.name, 3
						)
				
				if btnbind != null:
					_on_connection_request(
						btnbind.name, 0, output.name, 2
					)
					
			"ToggleExpression":
				output = _on_add_hotkey_pressed(preload("./graph/outputs/toggle_expression.tscn"))
				
				var name: String = hotkey.File.to_lower().left(-10).replace(" ", "_")
				var duration = hotkey.FadeSecondsAmount * 1000.0
				var animations = model.expressions
				for i in range(len(animations)):
					var a = animations[i]
					if a == name:
						output.get_node("%Expression").select(i)
				output.get_node("%Fade/Value").value = duration
				output.position_offset = Vector2(x + 280, y)
				
				if keybind != null:
					if hotkey.DeactivateAfterKeyUp:
						_on_connection_request(
							keybind.name, 0, output.name, 2
						)
						_on_connection_request(
							keybind.name, 1, output.name, 3
						)
					else:
						_on_connection_request(
							keybind.name, 0, output.name, 1
						)
				if btnbind != null:
					_on_connection_request(
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

func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	var from_action: GraphNode = graph.get_node(NodePath(from_node))
	var to_action: GraphNode = graph.get_node(NodePath(to_node))
	
	graph.connect_node(from_node, from_port, to_node, to_port)

func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	graph.disconnect_node(from_node, from_port, to_node, to_port)

func _on_child_entered_tree(node: Node) -> void:
	if node is GraphNode:
		node.slot_updated.connect(_on_action.bind(node))
		
func _on_action(slot: int, node: GraphNode):
	for conn in graph.get_connection_list():
		if not (conn.from_node == node.name and conn.from_port == slot):
			continue
			
		var target = graph.get_node(NodePath(conn.to_node))
			
		match node.get_output_port_type(slot):
			VtAction.SlotType.TRIGGER:
				target.invoke_trigger(conn.to_port)
			VtAction.SlotType.NUMERIC:
				var value_node = node.get_child(slot).get_node("Value")
				var value: float
				if value_node is LineEdit:
					value = float(value_node.text)
				else:
					value = float(value_node.value)
				target.update_value(conn.to_port, value)
			VtAction.SlotType.STRING:
				var value_node = node.get_child(slot).get_node("Value")
				var value: String = value_node.text
				target.update_value(conn.to_port, value)
			VtAction.SlotType.BOOL:
				var value_node = node.get_child(slot).get_node("Value")
				var value: bool = value_node.button_pressed
				target.update_value(conn.to_port, value)

func _on_delete_nodes_request(nodes: Array[StringName]) -> void:
	for i in nodes:
		var n = graph.get_node(NodePath(i))
		var x = graph_elements.find(n)
		
		if x > -1:
			graph_elements.remove_at(x)
		
		n.queue_free()
		
