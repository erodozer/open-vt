extends ConfirmationDialog

const VtItem = preload("res://lib/items/vt_item.gd")

var item: VtItem :
	set(i):
		item = i
		if i == null:
			return
		
		%Preview.add_child(item)
		
		%Preview/Camera2D.position = Vector2.ZERO
		var ratio = min(
				%Preview.get_size().x / item.size.x,
				%Preview.get_size().y / item.size.y,
				1.0
			)
		%Preview/Camera2D.zoom = Vector2.ONE * ratio
		
		%ZIndex/Value.value = 0
		%Pin/Value.set_pressed_no_signal(false)
		
		match item.item_type:
			VtItem.ItemType.ANIMATED:
				%FrameRate.show()
				%FrameRate/Value.value = item.render.sprite_frames.get_animation_speed("default")

func _on_flip_toggled(toggled_on: bool) -> void:
	item.render.scale = Vector2(-1 if toggled_on else 1, 1)

func _on_framerate_changed(value: float) -> void:
	assert(item.item_type == VtItem.ItemType.ANIMATED)
	var frames = item.render.sprite_frames as SpriteFrames
	frames.set_animation_speed("default", value)

func _on_pinnable_toggled(toggled_on: bool) -> void:
	item.pinnable = toggled_on

func _on_sortorder_changed(value: float) -> void:
	item.sort_order = int(value)

func _on_canceled() -> void:
	item.queue_free()
	item = null

func show_item(new_item: VtItem):
	item = new_item
	show()
