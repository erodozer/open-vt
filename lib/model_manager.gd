extends Node

const Files = preload("res://lib/utils/files.gd")
const ModelMeta = preload("res://lib/model/metadata.gd")
const VtModel = preload("res://lib/model/vt_model.gd")
const TrackingSystem = preload("res://lib/tracking/tracking_system.gd")

const FILE_DIR = "user://Live2DModels"

var model_cache: Dictionary = {}
signal list_updated(models: Array)

func _ready() -> void:
	refresh_models.call_deferred()
	add_to_group("system:model")
	
func load_data(path: String) -> ModelMeta:
	var vt_file = ""

	var files = Array(DirAccess.get_files_at(path))
	for f in files:
		if f.ends_with("vtube.json"):
			vt_file = path.path_join(f)
			break
			
	if vt_file.is_empty():
		return null
				
	var vtube_data = Files.read_json(vt_file)
	var model_data = Files.read_json(vt_file.get_base_dir().path_join(vtube_data["FileReferences"]["Model"]))
		
	var meta = ModelMeta.new()
	var base_name = vt_file.get_file()
	var ext = base_name.find(".")
	base_name = base_name.left(ext)
	meta.name = vtube_data["Name"]
	meta.path = path
	meta.id = vtube_data["ModelID"]
	meta.model = vt_file.get_base_dir().path_join(vtube_data["FileReferences"]["Model"])
	meta.format = "l2d"
	meta.studio_parameters = vt_file
	meta.openvt_parameters = "%s/%s.ovt.json" % [meta.model.get_base_dir(), base_name]
	meta.model_parameters = vt_file.get_base_dir().path_join(model_data["FileReferences"]["DisplayInfo"])
	meta.icon = "" if vtube_data.get("FileReferences", {}).get("Icon", "").is_empty() else vt_file.get_base_dir().path_join(vtube_data.get("FileReferences", {}).get("Icon", ""))
	meta.last_updated = String(vtube_data.get("ModelSaveMetadata", {}).get("LastSavedDateUnixMillisecondTimestamp", "0")).to_int() / 1000.0
	return meta
	
func refresh_models():
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(FILE_DIR)):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FILE_DIR))
	
	var model_folders = DirAccess.get_directories_at(FILE_DIR)
	model_cache = {}
	for i in model_folders:
		var fp = FILE_DIR.path_join(i)
		var meta = load_data(fp)
		if meta:
			model_cache[meta.id] = meta
		
	var models = model_cache.values()
	list_updated.emit(models)
	
	return models

func make_model(model):
	var data
	if model in model_cache:
		data = model_cache[model]
	else:
		data = load_data(model)
				
	if data == null:
		return
	
	var new_model: VtModel = preload("res://lib/model/vt_model.tscn").instantiate()
	match data.format:
		"l2d":
			var strategy = preload("res://lib/model/formats/l2d/model_strategy.gd").new()
			new_model.format_strategy = strategy
			new_model.model = data
			strategy.name = "FormatStrategy"
			new_model.add_child(strategy)
			new_model.render = strategy
	
	var tracking: TrackingSystem = get_tree().get_first_node_in_group("system:tracking")
	tracking.parameters_updated.connect(new_model.tracking_updated)
	
	new_model.display_name = data.name
	
	return new_model
	
