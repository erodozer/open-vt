extends "./blueprint_loader.gd"

const Serializers = preload("res://lib/utils/serializers.gd")

func id() -> StringName:
	return "ovt"
	
func load_graph(model: VtModel) -> Array:
	var ovt_data: Dictionary = Files.read_json(model.modelmeta.openvt_parameters)
	if ovt_data.is_empty():
		return []
		
	var graphs: Dictionary = ovt_data.get("graphs", {})
	if graphs.is_empty():
		return []
	
	var valid_graphs = []
	for profile in graphs:
		var graph: Blueprint = BlueprintTemplate.instantiate()
		graph.name = profile
		add_child(graph)
		_deserialize(graph, model, graphs[profile])
		if graph.get_child_count() > 0:
			valid_graphs.append(graph)
		remove_child(graph)
		
	return valid_graphs

func _deserialize(graph: Blueprint, model: VtModel, data: Dictionary):
	for i in data.get("nodes", []):
		var id = i.get("id", "")
		if id.is_empty():
			continue
		var n = graph.create_action(StringName(i.type))
		
		if n != null:
			n.id = id
			n.model = model
			n.deserialize(i.get("parameters", {}))
			n = graph.spawn_action(n, model)
		
		if n == null:
			push_error("invalid action type (%s), clearing graph" % i.type)
			graph.clear_connections()
			for c in graph.get_children():
				c.queue_free()
			return 
		
		
		
		n.position_offset = Serializers.Vec2Serializer.from_json(i.get("position"), Vector2.ZERO)
		
	for i in data.get("bindings", []):
		if i.src in graph.graph_elements and i.dst in graph.graph_elements:
			var from_node: VtAction = graph.graph_elements[i.src]
			var to_node: VtAction = graph.graph_elements[i.dst]
			if from_node == null or to_node == null:
				continue
			var src_slot = "{0}".format([i.src_slot])
			var dst_slot = "{0}".format([i.dst_slot])
			var src_port = from_node.get_output_port_by_name(src_slot)
			var dst_port = to_node.get_input_port_by_name(dst_slot)
			if src_port == -1:
				push_error("invalid slot in graph connection (node: {0}, src: {1})".format([from_node.name, src_slot]))
				continue
			if src_port == -1:
				push_error("invalid slot in graph connection (node: {0}, dst: {1})".format([to_node.name, dst_slot]))
				continue
			graph._on_connection_request.call_deferred(
				from_node.name, src_port,
				to_node.name, dst_port
			)
			
	graph.process_mode = PROCESS_MODE_INHERIT if data.get("enabled", true) else PROCESS_MODE_DISABLED
