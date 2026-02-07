extends Window

const Files = preload("res://lib/utils/files.gd")
const VtModel = preload("res://lib/model/vt_model.gd")
const VtItem = preload("res://lib/items/vt_item.gd")
const VtAction = preload("res://lib/blueprints/vt_action.gd")

const Blueprint = preload("res://lib/blueprints/blueprint.gd")
const Stage = preload("res://studio/stage/stage.gd")

const GRAPH_NODES_DIR = "res://studio/action_engine/graph"
static var INPUTS_DIR = GRAPH_NODES_DIR.path_join("inputs")
static var OUTPUTS_DIR = GRAPH_NODES_DIR.path_join("outputs")

@onready var screen_controller = get_tree().get_first_node_in_group("system:hotkey")

var active_model: VtModel

var active_profile: int :
	get():
		return %Profiles.current_tab

var active_graph: Blueprint :
	get():
		return %Profiles.get_child(active_profile)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in %Profiles.get_children():
		i.queue_free()
	
	await get_tree().process_frame
	
	for g in active_model.blueprints:
		g.reparent(%Profiles)
	
	self.title = "Model Bindings [%s]" % active_model.display_name
	
	# make sure to clean up the window when models are removed
	active_model.tree_exited.connect(
		func ():
			queue_free()
	)
	
	%AddBlueprint.get_popup().id_pressed.connect(
		func (id):
			var graphs = []
			match id:
				0:
					var graph = preload("res://lib/blueprints/blueprint.tscn").instantiate()
					graph.name = "New Profile"
					graphs.append(graph)
				1:
					graphs = BlueprintManager["loader/vts"].load_graph(active_model)
				2:
					graphs = BlueprintManager["loader/l2d"].load_graph(active_model)
			for graph in graphs:
				%Profiles.add_child(graph, true)
			%Profiles.current_tab = %Profiles.get_tab_count() - 1
	)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if active_model:
			# reattach graphs to model before deletion
			active_model.blueprints = %Profiles.get_children()

func _on_add_hotkey_pressed(node: VtAction, graph: GraphEdit = active_graph, model: VtModel = active_model) -> VtAction:
	node.model = model
	graph.add_child(node)
	node.position_offset = (graph.scroll_offset + graph.size / 2) / graph.zoom - node.size / 2
	return node
	
func save_settings(model_data: Dictionary):
	var graphs = model_data.get("graphs", {})
	
	for i in %Profiles.get_children():
		graphs[i.name] = i.serialize()
		
	model_data["graphs"] = graphs
	
func _on_profile_name_text_changed(new_text: String) -> void:
	active_graph.name = new_text
	
func _on_profile_enabled_toggled(toggled_on: bool) -> void:
	active_graph.process_mode = PROCESS_MODE_INHERIT if toggled_on else PROCESS_MODE_DISABLED

func _on_delete_profile_pressed() -> void:
	%DeleteConfirmation.dialog_text = "Delete Profile %s\nThis action is Permanent" % active_graph.name
	%DeleteConfirmation.show()

func _on_palette_create_node(action: VtAction) -> void:
	active_graph.spawn_action(action, active_model)

func _on_close_requested() -> void:
	queue_free()

func _on_profiles_tab_selected(_tab: int) -> void:
	%ProfileName.text = %Profiles.get_current_tab_control().name
	%ProfileEnabled.set_pressed_no_signal(
		%Profiles.get_current_tab_control().process_mode != PROCESS_MODE_DISABLED
	)

func _on_delete_confirmed() -> void:
	active_graph.queue_free()
	await get_tree().process_frame
