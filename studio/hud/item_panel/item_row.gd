extends PanelContainer

const VtItem = preload("res://lib/items/vt_item.gd")
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
		
		return
	
	_on_transform_update(item.position, item.scale, item.rotation_degrees)
	item.pin_changed.connect(_update_pin_name)
	%PinToggle.button_pressed = item.pinnable
	item.transform_updated.connect(_on_transform_update)
	%Position/XValue.value_changed.connect(_update_transform)
	%Position/YValue.value_changed.connect(_update_transform)
	%Scale/Value.value_changed.connect(_update_transform)
	%Rotation/Value.value_changed.connect(_update_transform)

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
	%Position/XValue.set_value_no_signal(position.x)
	%Position/YValue.set_value_no_signal(position.y)
	%Scale/Value.set_value_no_signal(scale.x * 100.0)
	%Rotation/Value.set_value_no_signal(rotation)

func _update_transform(_value):
	if _lock_transform:
		return
	
	_lock_transform = true
	item.position = Vector2(
		%Position/XValue.value,
		%Position/YValue.value,
	)
	item.scale = Vector2.ONE * %Scale/Value.value / 100.0
	item.rotation_degrees = fmod(%Rotation/Value.value, 360.0)
	_lock_transform = false
