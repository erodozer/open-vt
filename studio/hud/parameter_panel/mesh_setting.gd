extends PanelContainer

const VtModel = preload("res://lib/model/vt_model.gd")
const Math = preload("res://lib/utils/math.gd")

var model: VtModel
var mesh: Node

func _ready():
	%PartName.text = mesh.name
	%PinToggle.button_pressed = mesh.get_meta("pinnable", true)
	%ColorMultiply.color = Math.v4rgba(mesh.get_instance_shader_parameter("color_multiply"))
	%ColorScreen.color = Math.v4rgba(mesh.get_instance_shader_parameter("color_screen"))
	%ColorToggle.button_pressed = mesh.get_instance_shader_parameter("color_override")

func _on_pin_toggle_toggled(toggled_on: bool) -> void:
	mesh.set_meta("pinnable", toggled_on)

func _on_color_changed(color: Color) -> void:
	mesh.modulate = %Color.color

func _on_color_toggle_toggled(toggled_on: bool) -> void:
	%ColorMultiply.visible = toggled_on
	%ColorScreen.visible = toggled_on
	mesh.set_instance_shader_parameter("color_override", toggled_on)
	mesh.set_instance_shader_parameter("color_multiply", %ColorMultiply.color)
	mesh.set_instance_shader_parameter("color_screen", %ColorScreen.color)

func _on_color_multiply_color_changed(color: Color) -> void:
	mesh.set_instance_shader_parameter("color_multiply", color)

func _on_color_screen_color_changed(color: Color) -> void:
	mesh.set_instance_shader_parameter("color_screen", color)
