extends Node

const ModelMeta = preload("res://lib/model/metadata.gd")
const VtModel = preload("res://lib/model/vt_model.gd")
const TrackingSystem = preload("res://lib/tracking/tracking_system.gd")

const MODEL_DIR = "user://Live2DModels"

var model_cache: Dictionary = {}
signal list_updated(models: Array)

func _ready() -> void:
	refresh_models.call_deferred()
	
func refresh_models():
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(MODEL_DIR)):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MODEL_DIR))
	
	var model_folders = DirAccess.get_directories_at(MODEL_DIR)
	var models: Array[String] = []
	for i in model_folders:
		var fp = MODEL_DIR.path_join(i)
		
		var files = Array(DirAccess.get_files_at(fp))
		var model_file: String
		for f in files:
			if f.ends_with("vtube.json"):
				model_file = fp.path_join(f)
			
		if not model_file:
			continue
			
		models.append(model_file)
		
	model_cache = {}
	for vt_file in models:
		var vtube_data = JSON.parse_string(FileAccess.get_file_as_string(vt_file))
		var model_data = JSON.parse_string(FileAccess.get_file_as_string(vt_file.get_base_dir().path_join(vtube_data["FileReferences"]["Model"])))
		
		var meta = ModelMeta.new()
		meta.name = vtube_data["Name"]
		meta.id = vtube_data["ModelID"]
		meta.model = vt_file.get_base_dir().path_join(vtube_data["FileReferences"]["Model"])
		meta.format = "l2d"
		meta.studio_parameters = vt_file
		meta.model_parameters = vt_file.get_base_dir().path_join(model_data["FileReferences"]["DisplayInfo"])
		meta.icon = load("res://branding/monochrome.svg") if vtube_data["FileReferences"].get("Icon", "").is_empty() else \
			ImageTexture.create_from_image(
				Image.load_from_file(vt_file.get_base_dir().path_join(vtube_data["FileReferences"]["Icon"]))
			)
		
		model_cache[meta.id] = meta
	
	list_updated.emit(model_cache.values())

func make_model(model):
	if model not in model_cache:
		return
	
	var data = model_cache[model]
	
	var new_model: VtModel = preload("res://lib/model/vt_model.tscn").instantiate()
	match data.format:
		"l2d":
			var strategy = preload("res://lib/model/formats/l2d/model_strategy.gd").new()
			new_model.format_strategy = strategy
			new_model.model = data
			strategy.name = "FormatStrategy"
			new_model.add_child(strategy)
	
	var tracking: TrackingSystem = get_tree().get_first_node_in_group("system:tracking")
	tracking.parameters_updated.connect(new_model.tracking_updated)
	
	return new_model
	
