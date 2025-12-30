extends ConfirmationDialog

const VtItem = preload("res://lib/items/vt_item.gd")
const VtModel = preload("res://lib/model/vt_model.gd")

var model: VtModel
var mesh: MeshInstance2D
var btn_group = ButtonGroup.new()

func _ready():
	var btn = _make_btn(null)
	%Meshes.add_child(btn)
	
	for i in model.get_meshes():
		if i.get_meta("pinnable", true):
			btn = _make_btn(i)
		%Meshes.add_child(btn)
	
	%Meshes.get_child(0).button_pressed = true
	%Search.items = %Meshes.get_children()

func _make_btn(m: MeshInstance2D):
	var btn = Button.new()
	btn.text = "-" if m == null else m.name
	btn.toggle_mode = true
	btn.button_group = btn_group
	btn.set_meta("mesh", m)
	return btn

func _on_confirmed() -> void:
	mesh = btn_group.get_pressed_button().get_meta("mesh", null)
	close_requested.emit()

func _on_canceled() -> void:
	close_requested.emit()

func _on_close_requested() -> void:
	queue_free()
