extends PanelContainer

const VtModel = preload("res://lib/model/vt_model.gd")
const Math = preload("res://lib/utils/math.gd")

var model: VtModel
var mesh: Node

func _ready():
	%PartName.text = mesh.name
	%PinToggle.button_pressed = mesh.get_meta("pinnable", true)
	
	var color_modifier: Dictionary = model.format_strategy.get_modifiers(mesh).get("Color", {})
	var colors = color_modifier.get("colors", {})
	for k in colors.keys():
		var color = ColorPickerButton.new()
		$MeshSetting.add_child(color)
		color.custom_minimum_size = Vector2i(48, 0)
		color.color = colors[k]
		color.color_changed.connect(
			_on_color_changed.bind(k)
		)
		color.tooltip_text = k
		color.visible = false
		
	%ColorToggle.button_pressed = color_modifier.get("enabled", false)

func _on_pin_toggle_toggled(toggled_on: bool) -> void:
	model.format_strategy.apply_modifier(mesh, {
		"type": "Pin",
		"enabled": toggled_on,
	})

func _on_color_changed(color: Color, key: String) -> void:
	model.format_strategy.apply_modifier(mesh, {
		"type": "Color",
		"colors": {
			key: color
		}
	})

func _on_color_toggle_toggled(toggled_on: bool) -> void:
	for c in $MeshSetting.get_children():
		if c is ColorPickerButton:
			c.visible = toggled_on
	model.format_strategy.apply_modifier(mesh, {
		"type": "Color",
		"enabled": toggled_on
	})
