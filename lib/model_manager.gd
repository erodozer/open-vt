extends Node

const Files = preload("res://lib/utils/files.gd")
const ModelMeta = preload("res://lib/model/metadata.gd")
const ModelLoader = preload("res://lib/model/formats/model_loader.gd")
const VtModel = preload("res://lib/model/vt_model.gd")
const TrackingSystem = preload("res://lib/tracking/tracking_system.gd")

var formats: Dictionary[String, ModelLoader] = {}

func _ready() -> void:
	add_to_group("system:model")
	
	formats = {
		"l2d": preload("res://lib/model/formats/l2d/model_loader.gd").new(),
		"vrm": preload("res://lib/model/formats/vrm/model_loader.gd").new(),
	}
	
func is_model(path: String) -> bool:
	for fmt in formats.values():
		if path.ends_with(fmt.supported_extension()):
			return true
	return false
	
func _get(property: StringName) -> Variant:
	for f in formats.keys():
		if "loader/%s" % [f] == property:
			return formats[f]
	return null

func make_model(model_path: String):
	var data: ModelMeta
	var format
	for fmt in formats.values():
		if model_path.ends_with(fmt.supported_extension()):
			data = fmt.load_data(model_path)
		if data != null:
			format = fmt
			break

	if data == null:
		return
	
	var new_model = preload("./model/vt_model.tscn").instantiate()
	var strategy = format.strategy()
	new_model.set_script(strategy)
	new_model.modelmeta = data

	var tracking: TrackingSystem = get_tree().get_first_node_in_group("system:tracking")
	tracking.parameters_updated.connect(new_model.tracking_updated)
	
	new_model.display_name = data.name
	
	return new_model
	
