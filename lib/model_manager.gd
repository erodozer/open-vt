extends Node

const Files = preload("res://lib/utils/files.gd")
const ModelMeta = preload("res://lib/model/metadata.gd")
const ModelLoader = preload("res://lib/model/formats/model_loader.gd")
const VtModel = preload("res://lib/model/vt_model.gd")
const TrackingSystem = preload("res://lib/tracking/tracking_system.gd")

var formats: Array[ModelLoader] = []

var model_cache: Dictionary = {}
signal list_updated(models: Array)

func _ready() -> void:
	refresh_models.call_deferred()
	add_to_group("system:model")
	
	formats = [
		preload("res://lib/model/formats/l2d/model_loader.gd").new(),
		preload("res://lib/model/formats/vrm/model_loader.gd").new()
	]
	
func _get(property: StringName) -> Variant:
	for f in formats:
		if "loader/%s" % [f.model_format()] == property:
			return f
	return null

func refresh_models():
	model_cache = {}

	for fmt in formats:
		var dir = fmt.model_directory()
		if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(dir)):
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
		
		var model_folders = DirAccess.get_directories_at(dir)
		for i in model_folders:
			var fp = dir.path_join(i)
			var meta = fmt.load_data(fp)
			if meta:
				model_cache[meta.id] = meta
		
	var models = model_cache.values()
	list_updated.emit(models)
	
	return models

func make_model(model):
	var data: ModelMeta
	if model in model_cache:
		data = model_cache[model]
	else:
		for fmt in formats:
			data = fmt.load_data(model)
			if data != null:
				break
	
	if data == null:
		return
	
	var new_model: VtModel = preload("res://lib/model/vt_model.tscn").instantiate()
	for fmt in formats:
		if data.format == fmt.model_format():
			var strategy = fmt.strategy()
			new_model.format_strategy = strategy
			new_model.model = data
			strategy.name = "FormatStrategy"
			new_model.add_child(strategy)
			new_model.render = strategy
			break
	
	var tracking: TrackingSystem = get_tree().get_first_node_in_group("system:tracking")
	tracking.parameters_updated.connect(new_model.tracking_updated)
	
	new_model.display_name = data.name
	
	return new_model
	
