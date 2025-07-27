extends PanelContainer

const VtModel = preload("res://lib/model/vt_model.gd")

var model: VtModel
var mesh: NodePath

func _ready():
	var m = model.get_node(mesh)
	%PartName.text = m.name
	%PinToggle.button_pressed = m.get_meta("pinnable", true)
	%Color.color = m.modulate

func _on_pin_toggle_toggled(toggled_on: bool) -> void:
	var path = mesh
	if model.smoothing and model.filter == TEXTURE_FILTER_NEAREST:
		path = NodePath("PixelSubviewport/SubViewport/" + String(mesh))
	var m = model.get_node(path)
	m.get_meta("pinnable", toggled_on)

func _on_color_changed(color: Color) -> void:
	var path = mesh
	if model.smoothing and model.filter == TEXTURE_FILTER_NEAREST:
		path = NodePath("PixelSubviewport/SubViewport/" + String(mesh))
	model.get_node(path).modulate = %Color.color
