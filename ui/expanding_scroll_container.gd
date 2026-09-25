extends ScrollContainer

@export var maximum_size: Vector2 = Vector2.ZERO

var _dirty = false
func _ready() -> void:
	var content = get_child(0)
	content.child_order_changed.connect(
		func ():
			_dirty = true
	)
	set_process_internal(true)
	_dirty = true

func _notification(what: int) -> void:
	if what == NOTIFICATION_INTERNAL_PROCESS and _dirty:
		var content = get_child(0).size
		custom_minimum_size = Vector2i(
			min(content.x, maximum_size.x),
			min(content.y, maximum_size.y)
		)
		_dirty = false
