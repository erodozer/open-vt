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

var active_model: VtModel

var active_profile: int :
	get():
		return %ProfileTabs.current_tab

var active_graph: GraphEdit :
	get():
		return %Profiles.get_child(active_profile)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in %Profiles.get_children():
		i.queue_free()
	
	%ProfileTabs.clear_tabs()
	
	await get_tree().process_frame
	
	for g in active_model.action_graphs:
		g.reparent(%Profiles)
	%ProfileTabs.current_tab = 0
	
	self.title = "Model Bindings [%s]" % active_model.display_name
	
	# make sure to clean up the window when models are removed
	active_model.tree_exited.connect(
		func ():
			queue_free()
	)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if active_model:
			# reattach graphs to model before deletion
			active_model.action_graphs = %Profiles.get_children()

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
	
	if self.is_queued_for_deletion():
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

func _on_palette_create_node(action: GraphNode) -> void:
	ActionGraphLoader.spawn_action(action, active_graph, active_model)

func _on_close_requested() -> void:
	queue_free()
