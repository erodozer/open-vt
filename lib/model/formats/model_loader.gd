@abstract extends RefCounted

const Files = preload("res://lib/utils/files.gd")
const ModelMeta = preload("res://lib/model/metadata.gd")
const VtModel = preload("res://lib/model/vt_model.gd")

@abstract func load_data(path: String) -> ModelMeta

@abstract func model_format() -> StringName

@abstract func supported_extension() -> String

@abstract func strategy() -> Script
