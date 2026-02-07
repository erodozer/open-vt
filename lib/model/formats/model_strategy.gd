@abstract
extends Node2D

const ModelMeta = preload("../metadata.gd")

@abstract func is_initialized() -> bool

@abstract func load_model() -> bool

@abstract func get_size() -> Vector2

@abstract func get_origin() -> Vector2

@abstract func get_meshes() -> Array

@abstract func get_parameters() -> Dictionary[String, Dictionary]

@abstract func apply_parameters(values: Dictionary[String, float])

@abstract func apply_modifier(part: Node, modifier: Dictionary)

@abstract func get_modifiers(part: Node)

@abstract func get_texture() -> Texture2D

@abstract func on_filter_update(filter, smoothing)

@abstract func tracking_updated(tracking_data: Dictionary)
