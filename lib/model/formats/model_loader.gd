@abstract extends RefCounted

const Files = preload("res://lib/utils/files.gd")
const ModelMeta = preload("res://lib/model/metadata.gd")
const ModelStrategy = preload("res://lib/model/formats/model_strategy.gd")

@abstract func model_directory() -> String

@abstract func load_data(path: String) -> ModelMeta

@abstract func model_format() -> StringName

@abstract func supported_extension() -> String

@abstract func strategy() -> ModelStrategy
