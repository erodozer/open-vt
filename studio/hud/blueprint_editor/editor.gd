extends Window

const Files = preload("res://lib/utils/files.gd")
const VtModel = preload("res://lib/model/vt_model.gd")
const VtItem = preload("res://lib/items/vt_item.gd")

const Blueprint = preload("res://lib/blueprints/blueprint.gd")
const Stage = preload("res://studio/stage/stage.gd")

const GRAPH_NODES_DIR = "res://studio/action_engine/graph"
static var INPUTS_DIR = GRAPH_NODES_DIR.path_join("inputs")
static var OUTPUTS_DIR = GRAPH_NODES_DIR.path_join("outputs")

@onready var screen_controller = get_tree().get_first_node_in_group("system:hotkey")

var active_model: VtModel :
	set(model):
		for g in model.blueprints:
			g.reparent(%Profiles)
		# make sure to clean up the window when models are removed
		model.tree_exited.connect(
			func ():
				queue_free()
		)
		active_model = model

var active_profile: int :
	get():
		return %Profiles.current_tab

var active_graph: Blueprint :
	get():
		return %Profiles.get_child(active_profile)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	assert(active_model != null, "Model must be set before editor is in scene tree")
	get_viewport().gui_embed_subwindows = true
	
	self.title = "Model Bindings [%s]" % active_model.display_name
	
	%AddBlueprint.get_popup().id_pressed.connect(
		func (id):
			var graphs = []
			match id:
				0:
					var graph = preload("res://lib/blueprints/blueprint.tscn").instantiate()
					graph.name = "New Profile"
					graphs.append(graph)
				1:
					graphs = await BlueprintManager["loader/vts"].load_graph(active_model)
				2:
					graphs = await BlueprintManager["loader/l2d"].load_graph(active_model)
			for graph in graphs:
				%Profiles.add_child(graph, true)
			%Profiles.current_tab = %Profiles.get_tab_count() - 1
	)
	
	%EditPopup.add_button("Delete", true, "Delete")
	%EditPopup.add_cancel_button("Cancel")
	
	self.propagate_call("set_theme", [get_tree().root.theme])

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		# reattach graphs to model before deletion
		active_model.blueprints = %Profiles.get_children()
		active_model.save_settings()

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

func _on_palette_create_node(action: VtAction) -> void:
	active_graph.spawn_action(action, active_model)

func _on_close_requested() -> void:
	queue_free()

func _on_profiles_tab_selected(_tab: int) -> void:
	reset_edit_popup()
	
func reset_edit_popup():
	var current_tab = %Profiles.get_current_tab_control()
	if current_tab:
		%ProfileName.text = %Profiles.get_current_tab_control().name
		%ProfileEnabled.set_pressed_no_signal(
			%Profiles.get_current_tab_control().process_mode != PROCESS_MODE_DISABLED
		)

func _on_edit_popup_custom_action(action: StringName) -> void:
	if action == "Delete":
		var g = active_graph
		%Profiles.remove_child(g)
		g.queue_free()
	%EditPopup.hide()

func _on_edit_popup_confirmed() -> void:
	active_graph.name = %ProfileName.text
	active_graph.process_mode = PROCESS_MODE_INHERIT if %ProfileEnabled.button_pressed else PROCESS_MODE_DISABLED

func _on_profiles_tab_clicked(_tab: int) -> void:
	if %TabClickTimer.time_left > 0:
		%EditPopup.position = Vector2i(get_visible_rect().size / 2) + (%EditPopup.size / 2)
		reset_edit_popup()
		%EditPopup.show()
	else:
		%TabClickTimer.start()
