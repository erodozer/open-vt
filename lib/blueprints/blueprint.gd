extends GraphEdit

const Serializers = preload("res://lib/utils/serializers.gd")
const VtModel = preload("res://lib/model/vt_model.gd")
const VtAction = preload("./vt_action.gd")

static var _action_types: Array[PackedScene] = [
	preload("res://lib/blueprints/inputs/hotkey_action.tscn"),
	preload("res://lib/blueprints/inputs/screen_button.tscn"),
	preload("res://lib/blueprints/inputs/tracker_input.tscn"),
	preload("res://lib/blueprints/logic/arithmetic.tscn"),
	preload("res://lib/blueprints/logic/blink.tscn"),
	preload("res://lib/blueprints/logic/breathe.tscn"),
	preload("res://lib/blueprints/logic/smoothing.tscn"),
	preload("res://lib/blueprints/logic/range_map.tscn"),
	preload("res://lib/blueprints/outputs/model_output.tscn"),
	preload("res://lib/blueprints/outputs/play_animation.tscn"),
	preload("res://lib/blueprints/outputs/toggle_expression.tscn"),
]

static var palette: Dictionary[StringName, PackedScene] = _action_types.reduce(
	func (acc, template: PackedScene):
		var action = template.instantiate() as VtAction
		acc[action.get_type()] = template
		return acc,
	{} as Dictionary[StringName, PackedScene]
)

static func create_action(type: StringName) -> VtAction:
	if type in palette:
		var node = palette[type].instantiate()
		return node
	return null
	
func spawn_action(action_type, model: VtModel, initial_parameters: Dictionary = {}) -> VtAction:
	var node: VtAction
	if action_type is VtAction:
		node = action_type
	elif action_type is StringName:
		node = create_action(action_type)
		
	if node == null:
		return null
		
	for i in initial_parameters:
		node.set(i, initial_parameters[i])
		
	if not node.can_spawn(self):
		return null
		
	node.graph = self
	node.model = model
	
	if node.id.is_empty():
		node.id = "%d" % rid_allocate_id()
		
	add_child(node, true)
	node.owner = self
	node.position_offset = (scroll_offset + size / 2) / zoom - node.size / 2
	return node

var graph_elements: Dictionary[String, GraphNode] = {}

func _ready() -> void:
	add_valid_connection_type(VtAction.SlotType.VECTOR, VtAction.SlotType.NUMERIC)

func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	if not is_node_ready():
		await self.ready
		
	var n1: VtAction = get_node(NodePath(from_node))
	var n2: VtAction = get_node(NodePath(to_node))
	
	var s1: int = n1.get_output_slot_by_port(from_port)
	var s2: int = n2.get_input_slot_by_port(to_port)
	
	var slot_type = n2.get_input_type(s1)
	# fail to connect
	if slot_type == -1:
		return
		
	var count = get_connection_count(to_node, to_port)
	
	# only allow more than one binding for Trigger type
	if slot_type != VtAction.SlotType.TRIGGER and count > 0:
		var disconnected = connections.filter(
			func (f):
				return f.to_node == to_node and f.to_port == to_port
		)
		for i in disconnected:
			disconnect_node(i.from_node, i.from_port, to_node, to_port)
		
	connect_node(from_node, from_port, to_node, to_port)
	n2.bind(s2, n1)

func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	disconnect_node(from_node, from_port, to_node, to_port)

	var source: VtAction = get_node(NodePath(from_node))
	var target: VtAction = get_node(NodePath(to_node))
	if target != null:
		var field = target.get_input_port_slot(to_port)
		target.unbind(field, source)
		target.reset_value(field)

func _on_child_entered_tree(node: Node) -> void:
	if node is not VtAction:
		return
	
	var id = node.id
	assert(not id.is_empty(), "node has invalid id")
	
	graph_elements[id] = node
	node.slot_updated.connect(_on_action.bind(node))
	
func _on_child_exiting_tree(node: Node) -> void:
	if node is not VtAction:
		return
	
	var id = node.id
	if not id.is_empty() and id in graph_elements:
		graph_elements.erase(id)
	node.slot_updated.disconnect(_on_action.bind(node))
		
func _on_action(from_port: int, node: VtAction):
	for conn in get_connection_list():
		if not (conn.from_node == node.name and conn.from_port == from_port):
			continue
			
		var target: VtAction = get_node(NodePath(conn.to_node))
		if target == null:
			continue
			
		var from_slot = node.get_output_slot_by_port(from_port)
		var output = node.get_output_type(from_slot)
		var to_slot = target.get_input_slot_by_port(conn.to_port)
		var input = target.get_input_type(to_slot)
		if to_slot == -1:
			continue
		match output:
			VtAction.SlotType.TRIGGER:
				target.invoke_trigger(to_slot)
			_:
				var value = node.get_value(from_slot)
				if input == VtAction.SlotType.NUMERIC and output == VtAction.SlotType.VECTOR:
					var vec = value as Vector3
					target.update_value(to_slot, vec.z)
				else:
					target.update_value(to_slot, value)

func _on_delete_nodes_request(nodes: Array[StringName]) -> void:
	for i in nodes:
		var n = get_node(NodePath(i))
		n.queue_free()
		
func serialize() -> Dictionary:
	var nodes = []
	var bindings = []
	
	for i in graph_elements.values():
		var node = {
			"id": i.id,
			"type": i.get_type(),
			"position": Serializers.Vec2Serializer.to_json(i.position_offset),
			"parameters": i.serialize(),
		}
		nodes.append(node)
	
	for i in connections:
		var from_node: VtAction = get_node(NodePath(i.from_node))
		var from_id = from_node.id if from_node else -1
		var to_node: VtAction = get_node(NodePath(i.to_node))
		var to_id = to_node.id if to_node else -1
		var from_slot = from_node.get_output_slot_by_port(i.from_port)
		var to_slot = to_node.get_input_slot_by_port(i.to_port)
		var from_name = from_node.get_slot_name(from_slot)
		var to_name = to_node.get_slot_name(to_slot)
		bindings.append({
			"src": from_id,
			"dst": to_id,
			"src_slot": from_name,
			"dst_slot": to_name,
		})
		
	return {
		"enabled": process_mode != PROCESS_MODE_DISABLED,
		"nodes": nodes,
		"bindings": bindings,
	}
