extends "../model_loader.gd"

func model_directory() -> String:
	return "user://VrmModels"

func model_format() -> StringName:
	return "vrm"
	
func supported_extension() -> String:
	return ".vrm"

func strategy() -> ModelStrategy:
	return preload("res://lib/model/formats/vrm/model_strategy.gd").new()

func load_data(path: String) -> ModelMeta:
	var model_file: String = ""
	for file in Array(DirAccess.get_files_at(path)):
		if file.ends_with(supported_extension()):
			model_file = path.path_join(file)
	
	if model_file.is_empty():
		return null
	
	var meta = ModelMeta.new()
	
	var base_name = ""
	base_name = model_file.get_file()
	meta.name = base_name
	meta.id = base_name
	meta.model = model_file
	meta.path = path
	meta.format = model_format()
	meta.openvt_parameters = "%s/%s.ovt.json" % [meta.model.get_base_dir(), base_name]
	
	return meta
