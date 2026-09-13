extends Container

func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		var window = get_window()
		var scale = window.get_stretch_transform().get_scale()
		$SubViewportContainer.scale = Vector2(1., 1.) / scale
		$SubViewportContainer.size = window.size
