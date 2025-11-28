@abstract extends Node

const Files = preload("res://lib/utils/files.gd")
const VtModel = preload("res://lib/model/vt_model.gd")
const VtItem = preload("res://lib/items/vt_item.gd")
const VtAction = preload("res://lib/blueprints/vt_action.gd")

const Blueprint = preload("res://lib/blueprints/blueprint.gd")
const BlueprintTemplate = preload("res://lib/blueprints/blueprint.tscn")
const Stage = preload("res://studio/stage/stage.gd")

const GRAPH_NODES_DIR = "res://studio/action_engine/graph"
static var INPUTS_DIR = GRAPH_NODES_DIR.path_join("inputs")
static var OUTPUTS_DIR = GRAPH_NODES_DIR.path_join("outputs")

func _ready() -> void:
	const Stage = preload("res://studio/stage/stage.gd")
	var stage: Stage = get_tree().get_first_node_in_group("system:stage")
	if stage:
		stage.item_added.connect(
			func (item: VtItem):
				if item.render is VtModel:
					_register_graph(item.render)
		)
		stage.model_changed.connect(
			func (model: VtModel):
				_register_graph(model)
		)
	
@abstract func load_graph(model: VtModel) -> Array[Blueprint]

func _register_graph(model: VtModel):
	if model.blueprints.is_empty():
		model.blueprints = load_graph(model)
