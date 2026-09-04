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
		%ModelControls.show()
	else:
		item.pin_changed.connect(_update_pin_name)
		%PinToggle.button_pressed = item.pinnable
		if item.item_type == VtItem.ItemType.IMAGE:
			%Icon.icon = preload("./static_image.svg")
		elif item.item_type == VtItem.ItemType.ANIMATED:
			%Icon.icon = preload("./animated_image.svg")
			%AnimControls.show()
			%FpsValue.value = item.render.speed_scale * item.render.sprite_frames.get_animation_speed("default")
		elif item.item_type == VtItem.ItemType.MODEL:
			%Icon.icon = preload("./motion.svg")
			%ModelControls.show()
	
	_on_transform_update(item.position, item.scale, item.rotation_degrees, Vector2.ZERO, Vector3.ZERO)
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

func _on_transform_update(position: Vector2, scale: Vector2, rotation: float, offset: Vector2 = Vector2.ZERO, ypr: Vector3 = Vector3.ZERO) -> void:
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

func _on_edit_bindings_pressed() -> void:
	assert(item is VtModel or item.item_type == VtItem.ItemType.MODEL)
	var key = "{name}_{uid}_blueprints".format({"name": item.name, "uid": item.uid })
	var popup = WindowManager.get_popup(
		key,
		func ():
			var editor = load("res://studio/hud/blueprint_editor/editor.tscn").instantiate()
			editor.active_model = item if item is VtModel else item.render as VtModel
			editor.visible = true
			item.tree_exiting.connect(WindowManager.close_popup.bind(key))
			
			return editor
	)
	popup.grab_focus()

func _on_recenter_pressed() -> void:
	%XValue.editable = false
	%YValue.editable = false
	var t = create_tween()
	t.tween_property(
		item, "position", item.get_viewport_rect().get_center(), 0.2
	).set_trans(Tween.TRANS_QUAD)
	t.tween_callback(
		func ():
			item.notify_transform_updated()
			%XValue.editable = true
			%YValue.editable = true
	)

func _on_scale_to_fit_pressed() -> void:
	%Scale.editable = false
	var t = create_tween()
	t.tween_property(
		item, "scale", Vector2.ONE * min(1.0, item.get_viewport_rect().size.y / item.size.y), 0.2
	).set_trans(Tween.TRANS_QUAD)
	t.tween_callback(
		func ():
			item.notify_transform_updated()
			%Scale.editable = true
	)

func _on_fps_value_value_changed(value: float) -> void:
	var frames = item.render.sprite_frames as SpriteFrames
	var sprite = item.render as AnimatedSprite2D
	
	var fps = frames.get_animation_speed("default")
	sprite.speed_scale = value / float(fps)

func _on_reset_fps_pressed() -> void:
	var frames = item.render.sprite_frames as SpriteFrames
	%FpsValue.value = frames.get_animation_speed("default")

func _on_expression_pressed() -> void:
	var key = "{name}_{uid}_expressions".format({"name": item.name, "uid": item.uid })
	var popup = WindowManager.get_popup(
		key,
		func ():
			var window = load("res://studio/hud/item_panel/expression_selector/expression_selector.tscn").instantiate()
			window.item = item.render if item is VtItem else item
			item.tree_exiting.connect(WindowManager.close_popup.bind(key))
			return window
	)
	popup.grab_focus()

func _on_pin_target_pressed() -> void:
	var key = "{name}_{uid}_pin".format({"name": item.name, "uid": item.uid })
	var popup = WindowManager.get_popup(
		key,
		func ():
			var window = load("res://studio/hud/item_panel/pin_selector/pin_selector.tscn").instantiate()
			window.model = model
			window.confirmed.connect(
				func ():
					%PinTarget.text = "-" if window.mesh == null else window.mesh.name
					item.pinned_to = window.mesh
			)
			return window
	)
	popup.grab_focus()

func _on_model_settings_pressed() -> void:
	var key = "{name}_{uid}_settings".format({"name": item.name, "uid": item.uid })
	var popup = WindowManager.get_popup(
		key,
		func ():
			var popup = preload("./model_settings/panel.tscn").instantiate()
			popup.model = item.render if item is VtItem else item
			item.tree_exiting.connect(WindowManager.close_popup.bind(key))
			return popup
	)
	popup.grab_focus()

func _on_rotate_reset_pressed() -> void:
	%Rotation.editable = false
	var target = 360.0 if 360.0 - %Rotation.value < %Rotation.value else 0.0
		
	var t = create_tween()
	t.tween_property(
		%Rotation, "value", target, 0.2
	).set_trans(Tween.TRANS_QUAD)
	t.tween_callback(
		func ():
			%Rotation.value = wrapi(%Rotation.value, %Rotation.min_value, %Rotation.max_value)
			%Rotation.editable = true
	)

func _on_rotate_pressed(degrees: float) -> void:
	%Rotation.editable = false
	var t = create_tween()
	t.tween_property(
		%Rotation, "value", degrees, 0.2
	).set_trans(Tween.TRANS_QUAD).as_relative()
	t.tween_callback(
		func ():
			%Rotation.value = wrapi(%Rotation.value, %Rotation.min_value, %Rotation.max_value)
			%Rotation.editable = true
	)

func _on_scale_reset_pressed() -> void:
	%Scale.editable = false
	var t = create_tween()
	t.tween_property(
		item, "scale", Vector2.ONE, 0.2
	).set_trans(Tween.TRANS_QUAD)
	t.tween_callback(
		func ():
			item.notify_transform_updated()
			%Scale.editable = true
	)
