extends Control

func _on_model_changed(model: Node) -> void:
	model.reparent(self)
