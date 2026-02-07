@abstract
extends Node2D

const ModelMeta = preload("../metadata.gd")

@export var parameters: Dictionary :
	get():
		return get_parameters()

@export var meshes: Array :
	get():
		return get_meshes()

@abstract func is_initialized() -> bool

@abstract func load_model() -> bool

@abstract func get_size() -> Vector2

@abstract func get_origin() -> Vector2

@abstract func get_meshes() -> Array

@abstract func get_parameters() -> Dictionary

@abstract func apply_parameters(values)

@abstract func on_filter_update(filter, smoothing)

@abstract func tracking_updated(tracking_data: Dictionary)
