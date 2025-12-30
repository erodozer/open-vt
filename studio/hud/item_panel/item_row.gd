extends PanelContainer

const VtItem = preload("res://lib/items/vt_item.gd")
const VtModel = preload("res://lib/model/vt_model.gd")
const VtObject = preload("res://lib/vtobject.gd")

@export var model: VtModel
@export var item: VtObject

var _lock_transform = false

func _ready() -> void:
	%ItemName.text = item.display_name
	
	if item is not VtItem:
		%PinControls.hide()
		%ZControls.hide()
		%DeleteButton.hide()
	else:
		item.pin_changed.connect(_update_pin_name)
		%PinToggle.button_pressed = item.pinnable
		if item.item_type == VtItem.ItemType.IMAGE:
			%Icon.texture = preload("./static_image.svg")
		elif item.item_type == VtItem.ItemType.ANIMATED:
			%Icon.texture = preload("./animated_image.svg")
			%AnimControls.show()
			%FpsValue.value = item.render.speed_scale * item.render.sprite_frames.get_animation_speed("default")
		elif item.item_type == VtItem.ItemType.MODEL:
			%Icon.texture = preload("./motion.svg")
			%ModelControls.show()
	
	_on_transform_update(item.position, item.scale, item.rotation_degrees)
	item.transform_updated.connect(_on_transform_update)
	%XValue.value_changed.connect(_update_transform)
	%YValue.value_changed.connect(_update_transform)
	%Scale.value_changed.connect(_update_transform)
	%Rotation.value_changed.connect(_update_transform)
	
func _update_pin_name(mesh: MeshInstance2D) -> void:
	if mesh == null:
		%PinTarget.text = ""
	else:
		%PinTarget.text = mesh.name

func _on_pin_toggle_toggled(toggled_on: bool) -> void:
	item.pinnable = toggled_on

func _on_delete_button_pressed() -> void:
	item.request_delete.emit()
	
func _on_lock_button_toggled(toggled_on: bool) -> void:
	item.locked = toggled_on

func _reorder(idx: int, relative: bool = true) -> void:
	var current = get_index()
	
	var lower_bound = 0
	var upper_bound = get_parent().get_child_count() - 1
	var target = idx if not relative else current + idx
	if target < lower_bound or target > upper_bound:
		return
	
	get_parent().move_child(
		self,
		target
	)
	item.get_parent().move_child(
		item,
		target
	)
	item.sort_order = target
	
func _on_up_button_pressed() -> void:
	_reorder(-1, true)
	
func _on_down_button_pressed() -> void:
	_reorder(1, true)

func _on_transform_update(position: Vector2, scale: Vector2, rotation: float) -> void:
	%XValue.set_value_no_signal(position.x)
	%YValue.set_value_no_signal(position.y)
	%Scale.set_value_no_signal(scale.x * 100.0)
	%Rotation.set_value_no_signal(rotation)

func _update_transform(_value):
	if _lock_transform:
		return
	
	_lock_transform = true
	item.position = Vector2(
		%XValue.value,
		%YValue.value,
	)
	item.scale = Vector2.ONE * %Scale.value / 100.0
	item.rotation_degrees = fmod(%Rotation.value, 360.0)
	_lock_transform = false

var editor: Window
func _on_edit_bindings_pressed() -> void:
	if editor != null:
		if editor.is_queued_for_deletion():
			editor = null
		else:
			editor.grab_focus()
			return
	
	assert(item.item_type == VtItem.ItemType.MODEL)
	editor = load("res://studio/hud/blueprint_editor/editor.tscn").instantiate()
	editor.active_model = item.render as VtModel
	editor.visible = true
	add_child(editor)

func _on_recenter_pressed() -> void:
	item.position = item.get_viewport_rect().get_center()

func _on_scale_to_fit_pressed() -> void:
	item.scale = Vector2.ONE * min(1.0, item.get_viewport_rect().size.y / item.size.y)

func _on_fps_value_value_changed(value: float) -> void:
	var frames = item.render.sprite_frames as SpriteFrames
	var sprite = item.render as AnimatedSprite2D
	
	var fps = frames.get_animation_speed("default")
	sprite.speed_scale = value / float(fps)

func _on_reset_fps_pressed() -> void:
	var frames = item.render.sprite_frames as SpriteFrames
	%FpsValue.value = frames.get_animation_speed("default")

func _on_expression_pressed() -> void:
	var popup = load("res://studio/hud/item_panel/expression_selector/expression_selector.tscn").instantiate()
	popup.item = item
	add_child(popup)

func _on_pin_target_pressed() -> void:
	var popup = load("res://studio/hud/item_panel/pin_selector/pin_selector.tscn").instantiate()
	popup.model = model
	popup.confirmed.connect(
		func ():
			%PinTarget.text = "-" if popup.mesh == null else popup.mesh.name
			item.mesh = popup.mesh
	)
	add_child(popup)
