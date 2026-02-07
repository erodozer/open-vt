extends "../model_loader.gd"

func model_directory() -> String:
	return "user://Live2DModels"

func model_format() -> StringName:
	return "l2d"
	
func supported_extension() -> String:
	return ".model3.json"

func strategy() -> ModelStrategy:
	return preload("res://lib/model/formats/l2d/model_strategy.gd").new()

func load_data(path: String) -> ModelMeta:
	var meta = ModelMeta.new()
	
	var base_name = ""
	var vt_file = ""
	var model_file = ""
	var files = Array(DirAccess.get_files_at(path))
	for f in files:
		if f.ends_with(".vtube.json"):
			vt_file = path.path_join(f)
			var vtube_data = Files.read_json(vt_file)
			var vt_file_refs = vtube_data.get("FileReferences", {})
			
			base_name = vt_file.get_file()
			var ext = base_name.find(".")
			base_name = base_name.left(ext)
			meta.name = vtube_data["Name"]
			meta.id = vtube_data["ModelID"]
			meta.model = vt_file.get_base_dir().path_join(vt_file_refs.get("Model", ""))
			meta.last_updated = String(vtube_data.get("ModelSaveMetadata", {}).get("LastSavedDateUnixMillisecondTimestamp", "0")).to_int() / 1000.0
			meta.icon = "" if vt_file_refs.get("Icon", "").is_empty() else vt_file.get_base_dir().path_join(vt_file_refs["Icon"])		

		if f.ends_with(".model3.json") and model_file.is_empty():
			model_file = path.path_join(f)
			base_name = model_file.get_file()
			meta.name = base_name
			meta.id = base_name
			meta.model = model_file
	
	if meta.model.is_empty():
		return null
				
	var model_data = Files.read_json(model_file)
	meta.path = path
	meta.format = model_format()
	meta.studio_parameters = vt_file
	meta.openvt_parameters = meta.model.get_base_dir().path_join("%s.ovt.json" % base_name)
	
	var file_refs = model_data.get("FileReferences", {})
	meta.physics = "" if file_refs.get("Physics", "").is_empty() else vt_file.get_base_dir().path_join(file_refs["Physics"])
	
	return meta
