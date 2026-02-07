extends PanelContainer

const VtModel = preload("res://lib/model/vt_model.gd")

var model: VtModel
var mesh: Node

var _is_3d: bool

func _ready():
	_is_3d = mesh is MeshInstance3D
	%PartName.text = mesh.name
	%PinToggle.button_pressed = mesh.get_meta("pinnable", true)
	%Color.color = _read_color()

func _on_pin_toggle_toggled(toggled_on: bool) -> void:
	mesh.set_meta("pinnable", toggled_on)

func _on_color_changed(color: Color) -> void:
	if _is_3d:
		var m = mesh as MeshInstance3D
		var count = m.mesh.get_surface_count()
		for i in range(count):
			var mat: BaseMaterial3D = m.mesh.surface_get_material(i)
			mat.albedo_color = %Color.color
	else:
		mesh.modulate = %Color.color

func _read_color():
	if _is_3d:
		var m = mesh as MeshInstance3D
		var count = m.mesh.get_surface_count()
		if count > 0:
			var mat: BaseMaterial3D = m.mesh.surface_get_material(0)
			return mat.albedo_color
	else:
		return mesh.modulate
