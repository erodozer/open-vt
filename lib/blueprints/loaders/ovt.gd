extends "./blueprint_loader.gd"

const Serializers = preload("res://lib/utils/serializers.gd")

func id() -> StringName:
	return "ovt"
	
func load_graph(model: VtModel) -> Array:
	var ovt_data: Dictionary = Files.read_json(model.model.openvt_parameters)
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
		n.set_meta("id", i.get("id", rid_allocate_id()))
		n.model = model
		graph.add_child(n, true)
		
		n.deserialize(i.get("parameters", {}))
		n.position_offset = Serializers.Vec2Serializer.from_json(i.get("position"), Vector2.ZERO)
		
	for i in data.get("bindings", []):
		if i.src in graph.graph_elements and i.dst in graph.graph_elements:
			graph._on_connection_request.call_deferred(
				graph.graph_elements[i.src].name, i.src_slot,
				graph.graph_elements[i.dst].name, i.dst_slot
			)
			
	graph.process_mode = PROCESS_MODE_INHERIT if data.get("enabled", true) else PROCESS_MODE_DISABLED
