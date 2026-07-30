extends PanelContainer

const VtModel = preload("res://lib/model/vt_model.gd")
const Math = preload("res://lib/utils/math.gd")

var model: VtModel
var mesh: Node

func _ready():
	%PartName.text = mesh.name
	%PinToggle.button_pressed = model.get("modifiers/meshes/%s/pinnable" % [mesh.name])
	
	for k in ["screen_color", "multiply_color"]:
		var color = ColorPickerButton.new()
		$MeshSetting.add_child(color)
		color.custom_minimum_size = Vector2i(48, 0)
		color.color = model.get("modifiers/meshes/%s/%s" % [mesh.name, k])
		color.color_changed.connect(
			_on_color_changed.bind(k)
		)
		color.tooltip_text = k
		color.visible = false
		
	%ColorToggle.button_pressed = model.get("modifiers/meshes/%s/color_override" % mesh.name)

func _on_pin_toggle_toggled(toggled_on: bool) -> void:
	model.set("modifiers/meshes/%s/pinnable" % mesh.name, toggled_on)
	
func _on_color_changed(color: Color, key: String) -> void:
	model.set("modifiers/meshes/%s/%s" % [mesh.name, key], color)

func _on_color_toggle_toggled(toggled_on: bool) -> void:
	for c in $MeshSetting.get_children():
		if c is ColorPickerButton:
			c.visible = toggled_on
	model.set("modifiers/meshes/%s/color_override" % mesh.name, toggled_on)
