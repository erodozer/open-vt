extends ConfirmationDialog

const VtModel = preload("res://lib/model/vt_model.gd")

var model: VtModel
var mesh: MeshInstance2D
var btn_group = ButtonGroup.new()

func _on_visibility_changed() -> void:
	if not visible:
		for i in %Meshes.get_children():
			i.queue_free()
	
	if visible:
		var btn = _make_btn(null)
		%Meshes.add_child(btn)
		
		for i in model.get_meshes():
			if i.get_meta("pinnable", true):
				btn = _make_btn(i)
			%Meshes.add_child(btn)
		
		%Meshes.get_child(0).button_pressed = true

func _make_btn(m: MeshInstance2D):
	var btn = Button.new()
	btn.text = "-" if m == null else m.name
	btn.toggle_mode = true
	btn.button_group = btn_group
	btn.toggled.connect(
		func (toggled):
			if toggled:
				mesh = m
	)
	return btn
