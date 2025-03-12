extends PanelContainer

const VtItem = preload("res://lib/items/vt_item.gd")
const VtObject = preload("res://lib/vtobject.gd")

@export var item: VtObject

func _ready() -> void:
	%ItemName.text = item.name
	
	if item is not VtItem:
		%LockButton.hide()
		%PinControls.hide()
		%ZControls.hide()
		%DeleteButton.hide()
		
		return
	
	item.pin_changed.connect(_update_pin_name)
	%PinToggle.button_pressed = item.pinnable

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
	
func _on_up_button_pressed() -> void:
	_reorder(-1, true)
	
func _on_down_button_pressed() -> void:
	_reorder(1, true)
