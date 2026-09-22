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
	content_scale_factor = get_tree().root.get_window().content_scale_factor
		
	%Profiles.get_tab_bar().tab_rmb_clicked.connect(_on_profiles_tab_menu)
	
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
				3:
					%ImportGraphDialog.popup_centered()
			for graph in graphs:
				%Profiles.add_child(graph, true)
			%Profiles.current_tab = %Profiles.get_tab_count() - 1
	)
	theme = get_tree().root.theme

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and is_instance_valid(active_model):
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
	if active_graph == null:
		return
	active_graph.spawn_action(action, active_model)

func _on_close_requested() -> void:
	queue_free()

func _on_profiles_tab_selected(_tab: int) -> void:
	pass

#region Edit context menu
var _editing: Blueprint

func _on_profiles_tab_menu(tab: int) -> void:
	_editing = %Profiles.get_child(tab)
	var ctrl = %Profiles.get_tab_bar().get_tab_rect(tab)
	var pos = %Profiles.get_tab_bar().global_position + ctrl.position + Vector2(0, ctrl.size.y)
	%EditMenu.set_item_checked(0, _editing.enabled)
	%EditMenu.position = pos
	%EditMenu.show()
	
func _on_edit_menu_id_pressed(id: int) -> void:
	match id:
		0: # Rename popup
			%RenameDialog/%LineEdit.text = _editing.name
			%RenameDialog.popup_centered()
		1: # Move Left
			%Profiles.move_child(_editing, clamp(_editing.get_index() - 1, 0, %Profiles.get_child_count()))
		2: # Move Right
			%Profiles.move_child(_editing, clamp(_editing.get_index() + 1, 0, %Profiles.get_child_count()))
		3: # Remove
			%Profiles.remove_child(_editing)
			_editing.queue_free()
			_editing = null
		4: # Export
			%ExportGraphDialog.popup_centered()
		5: # Toggle Enabled
			_editing.enabled = !_editing.enabled
		
func _on_edit_menu_popup_hide() -> void:
	%EditMenu.set_meta("context", null)

func _on_export_graph_dialog_file_selected(path: String) -> void:
	Files.write_json(
		path,
		_editing.serialize()
	)
	
func _on_rename_dialog_confirmed() -> void:
	_editing.name = %RenameDialog/%LineEdit.text

#endregion

func _on_import_graph_dialog_file_selected(path: String) -> void:
	var imported = BlueprintManager["loader/ovt"].load_graph(active_model, path)
	for graph in imported:
		%Profiles.add_child(graph, true)
	
