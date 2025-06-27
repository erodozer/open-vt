extends Node2D

func is_initialized() -> bool:
	return true

func load_model() -> bool:
	return false

func get_meshes() -> Array:
	return []

func get_parameters() -> Dictionary:
	return {}

func apply_parameters(values):
	pass

func on_filter_update(filter):
	push_warning("not implemented")

func on_smoothing_update(filter):
	push_warning("not implemented")

func tracking_updated(tracking_data: Dictionary):
	pass
