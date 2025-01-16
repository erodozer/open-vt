extends Node

const ModelMeta = preload("res://lib/model/metadata.gd")
const VtModel = preload("res://lib/model/vt_model.gd")

const MODEL_DIR = "user://Live2DModels"

var model_cache: Dictionary = {}
var active_model: VtModel

signal model_changed(model: VtModel)
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
		meta.studio_parameters = vt_file
		meta.model_parameters = vt_file.get_base_dir().path_join(model_data["FileReferences"]["DisplayInfo"])
		meta.icon = vt_file.get_base_dir().path_join(vtube_data["FileReferences"]["Icon"])
		model_cache[meta.id] = meta
	
	list_updated.emit(model_cache.values())

func activate_model(model):
	if model not in model_cache:
		return
	
	var data = model_cache[model]
	
	var new_model: VtModel = preload("res://lib/model/vt_model.tscn").instantiate()
	new_model.model = data
	
	if active_model != null:
		active_model.queue_free()
		
	new_model.ready.connect(
		func ():
			active_model = new_model
			model_changed.emit(active_model),
		CONNECT_ONE_SHOT
	)
	add_child(new_model)
	
func load_settings(data):
	if "active_model" in data:
		activate_model(data["active_model"])
	
func save_settings(data):
	data["active_model"] = active_model.model.id
	
