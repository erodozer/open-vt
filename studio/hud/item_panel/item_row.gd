extends PanelContainer

const VtItem = preload("res://lib/items/vt_item.gd")
const VtModel = preload("res://lib/model/vt_model.gd")
const VtObject = preload("res://lib/vtobject.gd")

@export var item: VtObject

var _lock_transform = false

func _ready() -> void:
	%ItemName.text = item.display_name
	
	if item is not VtItem:
		%LockButton.hide()
		%PinControls.hide()
		%ZControls.hide()
		%DeleteButton.hide()
		%Transformation.hide()
		%ModelControls.hide()
		return
	
	if item.item_type != VtItem.ItemType.MODEL:
		%ModelControls.hide()
	else:
		var model: VtModel = item.get_node("Render")
		
		for e in model.expressions:
			var idx = %Expressions.item_count
			%Expressions.add_item(e)
			%Expressions.set_item_metadata(idx, e)
	
	_on_transform_update(item.position, item.scale, item.rotation_degrees)
	item.pin_changed.connect(_update_pin_name)
	%PinToggle.button_pressed = item.pinnable
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
	queue_free()
	item.queue_free()
	
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

var editor
func _on_edit_bindings_toggled(toggled_on: bool) -> void:
	if editor != null:
		editor.queue_free()
		
	if toggled_on:
		editor = preload("res://studio/action_engine/action_editor.tscn").instantiate()
		var model = item.get_node("Render") as VtModel
		editor.active_model = model
		editor.visible = true
		add_child(editor)

func _on_expression_menu_confirmed() -> void:
	var model = item.get_node("Render") as VtModel
	var selected = %Expressions.get_selected_metadata()
	model.toggle_expression(selected, true, %Duration.value, %Exclusive.button_pressed)
