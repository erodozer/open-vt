extends GraphEdit

const Serializers = preload("res://lib/utils/serializers.gd")
const VtModel = preload("res://lib/model/vt_model.gd")
const VtAction = preload("./vt_action.gd")

static var _action_types: Array[PackedScene] = [
	preload("res://lib/blueprints/inputs/hotkey_action.tscn"),
	preload("res://lib/blueprints/inputs/screen_button.tscn"),
	preload("res://lib/blueprints/inputs/tracking_parameter.tscn"),
	preload("res://lib/blueprints/logic/arithmetic.tscn"),
	preload("res://lib/blueprints/logic/blink.tscn"),
	preload("res://lib/blueprints/logic/breathe.tscn"),
	preload("res://lib/blueprints/logic/smoothing.tscn"),
	preload("res://lib/blueprints/outputs/model_parameter.tscn"),
	preload("res://lib/blueprints/outputs/play_animation.tscn"),
	preload("res://lib/blueprints/outputs/toggle_expression.tscn")
]

static var palette: Dictionary[StringName, PackedScene] = _action_types.reduce(
	func (acc, template: PackedScene):
		var action = template.instantiate() as VtAction
		acc[action.get_type()] = template
		return acc,
	{} as Dictionary[StringName, PackedScene]
)

static func create_action(type: StringName) -> VtAction:
	return palette[type].instantiate()
	
func spawn_action(action_type, model: VtModel) -> VtAction:
	var node: VtAction
	if action_type is VtAction:
		node = action_type
	elif action_type is StringName:
		node = create_action(action_type)
	node.model = model
	
	add_child(node)
	node.position_offset = (scroll_offset + size / 2) / zoom - node.size / 2
	return node

var graph_elements: Dictionary[String, GraphNode] = {}

func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	if not is_node_ready():
		await self.ready
		
	var n1 = get_node(NodePath(from_node))
	var n2 = get_node(NodePath(to_node))
	
	var slot_type = n2.get_input_type(to_port)
	var count = get_connection_count(to_node, to_port)
	
	# only allow one binding for numeric, allow takeover
	if slot_type == VtAction.SlotType.NUMERIC and count > 0:
		var disconnected = connections.filter(
			func (f):
				return f.to_node == to_node and f.to_port == to_port
		)
		for i in disconnected:
			disconnect_node(i.from_node, i.from_port, to_node, to_port)
		
	connect_node(from_node, from_port, to_node, to_port)
	n2.bind(to_port, n1)

func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	disconnect_node(from_node, from_port, to_node, to_port)

	var source = get_node(NodePath(from_node))
	var target = get_node(NodePath(to_node))
	if target != null:
		target.unbind(to_port, source)
		target.reset_value(to_port)

func _on_child_entered_tree(node: Node) -> void:
	if node is VtAction:
		var id = node.get_meta("id", "")
		if id.is_empty():
			id = "%s" % rid_allocate_id()
			node.set_meta("id", id)
	
		graph_elements[id] = node
		node.slot_updated.connect(_on_action.bind(node))
	
func _on_child_exiting_tree(node: Node) -> void:
	if node is VtAction:
		var id = node.get_meta("id", "")
		if not id.is_empty() and id in graph_elements:
			graph_elements.erase(id)
		node.slot_updated.disconnect(_on_action.bind(node))
		
func _on_action(slot: int, node: VtAction):
	for conn in get_connection_list():
		if not (conn.from_node == node.name and conn.from_port == slot):
			continue
			
		var target = get_node(NodePath(conn.to_node))
		if target == null:
			continue
			
		var output = node.get_output_type(slot)
		match output:
			VtAction.SlotType.TRIGGER:
				target.invoke_trigger(conn.to_port)
			_:
				var value = node.get_value(slot)
				target.update_value(conn.to_port, value)

func _on_delete_nodes_request(nodes: Array[StringName]) -> void:
	for i in nodes:
		var n = get_node(NodePath(i))
		n.queue_free()
		
func serialize() -> Dictionary:
	var nodes = []
	var bindings = []
	
	for i in graph_elements.values():
		var node = {
			"id": i.get_meta("id"),
			"type": i.get_type(),
			"position": Serializers.Vec2Serializer.to_json(i.position_offset),
			"parameters": i.serialize(),
		}
		nodes.append(node)
	
	for i in connections:
		var from_node = get_node(NodePath(i.from_node)).get_meta("id")
		var to_node = get_node(NodePath(i.to_node)).get_meta("id")
		bindings.append({
			"src": from_node,
			"dst": to_node,
			"src_slot": i.from_port,
			"dst_slot": i.to_port,
		})
		
	return {
		"enabled": process_mode != PROCESS_MODE_DISABLED,
		"nodes": nodes,
		"bindings": bindings,
	}
