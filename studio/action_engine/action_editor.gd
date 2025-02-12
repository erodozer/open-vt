extends GraphEdit

const VtModel = preload("res://lib/model/vt_model.gd")
const VtAction = preload("./graph/vt_action.gd")

const GRAPH_NODES_DIR = "res://studio/action_engine/graph"
static var INPUTS_DIR = GRAPH_NODES_DIR.path_join("inputs")
static var OUTPUTS_DIR = GRAPH_NODES_DIR.path_join("outputs")

var graph_elements: Array[GraphNode] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for f in DirAccess.get_files_at(INPUTS_DIR):
		if f.get_extension() == "tscn":
			var p: PackedScene = load(INPUTS_DIR.path_join(f))
			var b = Button.new()
			b.text = "Add %s" % [p._bundled["names"][0]]
			b.pressed.connect(_on_add_hotkey_pressed.bind(p))
			%Inputs.add_child(b)
			
	for f in DirAccess.get_files_at(OUTPUTS_DIR):
		if f.get_extension() == "tscn":
			var p: PackedScene = load(OUTPUTS_DIR.path_join(f))
			var b = Button.new()
			b.text = "Add %s" % [p._bundled["names"][0]]
			b.pressed.connect(_on_add_hotkey_pressed.bind(p))
			%Outputs.add_child(b)

func _on_add_hotkey_pressed(node: PackedScene) -> GraphNode:
	var input = node.instantiate()
	input.position_offset = size / 2
	add_child(input)
	graph_elements.append(input)
	return input

func _on_stage_model_changed(model: VtModel) -> void:
	for i in graph_elements:
		i.queue_free()
		
	graph_elements.clear()
	
	# load vts hotkey settings
	var vtube_data = JSON.parse_string(FileAccess.get_file_as_string(model.model.studio_parameters))
	var y = 0
	var x = 0
	for hotkey in vtube_data.get("Hotkeys", []):
		var input = _on_add_hotkey_pressed(preload("./graph/inputs/hotkey_action.tscn"))
		var binding = input.get_node("%Handler")
		binding.load_from_vts(hotkey)
		input.position_offset = Vector2(x, y)
		input.get_node("%Input").text = " + ".join(binding.input_as_list)
		
		var output: GraphNode
		match hotkey.Action:
			"TriggerAnimation":
				output = _on_add_hotkey_pressed(preload("./graph/outputs/anim_action.tscn"))
				
				var anim_name = hotkey.File
				var duration = hotkey.FadeSecondsAmount * 1000.0				
				var animations = model.motions.get_animation_list()
				for i in range(len(animations)):
					var a = animations[i]
					if a == anim_name:
						output.get_node("%Animation").select(i + 1)
				output.get_node("%Delay/Value").value = duration
				output.position_offset = Vector2(x + 280, y)
				
				# pressed
				_on_connection_request(
					input.name, 0, output.name, 2
				)
				
				# released
				if hotkey.DeactivateAfterKeyUp:
					_on_connection_request(
						input.name, 1, output.name, 3
					)
		
		if output:
			y += max(output.size.y, input.size.y) + 30
		else:
			y += input.size.y + 30
			
		if y > 2500:
			x += 800
			y = 0

func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	var from_action: GraphNode = get_node(NodePath(from_node))
	var to_action: GraphNode = get_node(NodePath(to_node))
	
	connect_node(from_node, from_port, to_node, to_port)

func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	disconnect_node(from_node, from_port, to_node, to_port)

func _on_child_entered_tree(node: Node) -> void:
	if node is GraphNode:
		node.slot_updated.connect(_on_action.bind(node))
		
func _on_action(slot: int, node: GraphNode):
	for conn in get_connection_list():
		if not (conn.from_node == node.name and conn.from_port == slot):
			continue
			
		var target = get_node(NodePath(conn.to_node))
			
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
		var n = get_node(NodePath(i))
		var x = graph_elements.find(n)
		
		if x > -1:
			graph_elements.remove_at(x)
		
		n.queue_free()
		
