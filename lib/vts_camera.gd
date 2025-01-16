extends Camera2D

const utils = preload("res://lib/utils.gd")
const VTS_VIEWPORT = Vector2(1280, 720)

func _ready() -> void:
	get_viewport().size_changed.connect(_update_zoom)
	_update_zoom()

func _update_zoom():
	var viewport = get_viewport_rect()
	var scale_factor = viewport.size.y / utils.VTS_VIEWPORT.y
	# zoom = Vector2.ONE * scale_factor
