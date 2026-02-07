extends Node

const VtModel = preload("res://lib/model/vt_model.gd")
const BlueprintLoader = preload("./loaders/blueprint_loader.gd")

var formats: Array[BlueprintLoader]

func _ready() -> void:
	formats = [
		preload("./loaders/vts.gd").new(),
		preload("./loaders/ovt.gd").new(),
		preload("./loaders/l2d_defaults.gd").new(),
	]
	
	for f in formats:
		add_child(f)

func _get(property: StringName) -> Variant:
	for f in formats:
		if "loader/%s" % [f.id()] == property:
			return f
	return null

func register_graph(model: VtModel):
	if not model.blueprints.is_empty():
		return
		
	for f in formats:
		if not model.blueprints.is_empty():
			return
		model.blueprints = f.load_graph(model)
