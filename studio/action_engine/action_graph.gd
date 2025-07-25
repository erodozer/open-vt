extends GraphEdit

const VtAction = preload("./graph/vt_action.gd")

var graph_elements: Array[GraphNode] = []

func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	var n1 = get_node(NodePath(from_node))
	var n2 = get_node(NodePath(to_node)) 
	if n1.get_meta("profile") != n2.get_meta("profile"):
		return
	
	var slot_type = n2.get_input_port_type(to_port)
	var count = get_connection_count(to_node, to_port)
	
	# only allow one binding for numeric, allow takeover
	if slot_type == VtAction.SlotType.NUMERIC and count > 0:
		var disconnect = connections.filter(
			func (f):
				return f.to_node == to_node and f.to_port == to_port
		)
		for i in disconnect:
			disconnect_node(i.from_node, i.from_port, to_node, to_port)
		
	connect_node(from_node, from_port, to_node, to_port)

func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	disconnect_node(from_node, from_port, to_node, to_port)

	var target = get_node(NodePath(to_node))
	if target != null:
		if target.has_method("reset_value"):
			target.reset_value(to_port)

func _on_child_entered_tree(node: Node) -> void:
	if node is GraphNode:
		graph_elements.append(node)
		node.slot_updated.connect(_on_action.bind(node))
		
func _on_action(slot: int, node: GraphNode):
	for conn in get_connection_list():
		if not (conn.from_node == node.name and conn.from_port == slot):
			continue
			
		var target = get_node(NodePath(conn.to_node))
		if target == null:
			continue
			
		match node.get_output_port_type(slot):
			VtAction.SlotType.TRIGGER:
				target.invoke_trigger(conn.to_port)
			_:
				var value = node.get_value(slot)
				target.update_value(conn.to_port, value)

func _on_delete_nodes_request(nodes: Array[StringName]) -> void:
	for i in nodes:
		var n = get_node(NodePath(i))
		var x = graph_elements.find(n)
		
		if x > -1:
			graph_elements.remove_at(x)
		
		n.queue_free()
