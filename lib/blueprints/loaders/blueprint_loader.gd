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

@abstract func load_graph(model: VtModel) -> Array[Blueprint]

@abstract func id() -> StringName
