extends PanelContainer

const VtModel = preload("res://lib/model/vt_model.gd")

var model: VtModel
var mesh: Node

func _ready():
	%PartName.text = mesh.name
	%PinToggle.button_pressed = mesh.get_meta("pinnable", true)
	%Color.color = mesh.modulate

func _on_pin_toggle_toggled(toggled_on: bool) -> void:
	mesh.get_meta("pinnable", toggled_on)

func _on_color_changed(color: Color) -> void:
	mesh.modulate = %Color.color
