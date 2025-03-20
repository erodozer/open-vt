extends PanelContainer

const VtModel = preload("res://lib/model/vt_model.gd")

var model: VtModel
var mesh: NodePath

func _ready():
	var m = model.get_node(mesh)
	%PartName.text = m.name
	%PinToggle.button_pressed = model.pinnable[m.name]
	%Color.color = m.modulate

func _on_pin_toggle_toggled(toggled_on: bool) -> void:
	var m = model.get_node(mesh)
	model.pinnable[m.name] = toggled_on

func _on_color_changed(color: Color) -> void:
	model.get_node(mesh).modulate = %Color.color
