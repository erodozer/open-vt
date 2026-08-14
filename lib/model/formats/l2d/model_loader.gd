extends "../model_loader.gd"

func model_directory() -> String:
	return "user://Live2DModels"

func model_format() -> StringName:
	return "Live2D/Ayagami"
	
func supported_extension() -> String:
	return ".model3.json"

func strategy() -> Script:
	return preload("./model.gd")

func load_data(path: String) -> ModelMeta:
	var meta = ModelMeta.new()
	
	var base_dir = path.get_base_dir()
	var base_name = path.get_file().trim_suffix(supported_extension())
	var vt_file = base_dir.path_join("%s.vtube.json" % base_name)
	var ovt_file = base_dir.path_join("%s.ovt.json" % base_name)

	meta.name = base_name
	meta.id = base_name
	meta.model = path

	if FileAccess.file_exists(vt_file):
		var vtube_data = Files.read_json(vt_file)
		var vt_file_refs = vtube_data.get("FileReferences", {})
		meta.name = vtube_data["Name"]
		meta.id = vtube_data["ModelID"]
	
	var model_data = Files.read_json(path)
	meta.path = path.get_base_dir()
	meta.format = model_format()
	meta.studio_parameters = vt_file
	meta.openvt_parameters = ovt_file
	
	return meta
