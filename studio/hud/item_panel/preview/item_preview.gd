extends ConfirmationDialog

const VtItem = preload("res://lib/items/vt_item.gd")
const Stage = preload("res://studio/stage/stage.gd")

@onready var stage: Stage = get_tree().get_first_node_in_group("system:stage")

var item: VtItem

func _ready():
	%Preview.add_child(item)
	
	await get_tree().process_frame
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
	var sprite = item.render as AnimatedSprite2D
	
	var fps = frames.get_animation_speed("default")
	sprite.speed_scale = value / float(fps)

func _on_pinnable_toggled(toggled_on: bool) -> void:
	item.pinnable = toggled_on

func _on_sortorder_changed(value: float) -> void:
	item.sort_order = int(value)

func _on_confirmed() -> void:
	stage.spawn_item(item)
	close_requested.emit()

func _on_canceled() -> void:
	close_requested.emit()
	
func _on_close_requested() -> void:
	queue_free()
