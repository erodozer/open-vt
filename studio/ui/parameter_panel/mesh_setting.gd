extends PanelContainer

const VtModel = preload("res://lib/model/vt_model.gd")

var model: VtModel
var mesh: MeshInstance2D

func _ready():
	%PartName.text = mesh.name
	%PinToggle.button_pressed = model.pinnable[mesh.name]
	%Color.color = mesh.modulate

func _on_pin_toggle_toggled(toggled_on: bool) -> void:
	model.pinnable[mesh] = toggled_on

func _on_color_changed(color: Color) -> void:
	mesh.modulate = %Color.color
