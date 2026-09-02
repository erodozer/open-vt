extends "res://lib/model/modifier.gd"

var mesh: MeshInstance3D
@export var albedo: Color = Color.WHITE :
	set(v):
		if v == null:
			v = Color.WHITE
		albedo = v
		_update_color()

@export var emission: Color = Color.WHITE :
	set(v):
		if v == null:
			v = Color.WHITE
		emission = v
		_update_color()
		
@export var color_override: bool = false :
	set(v):
		color_override = v
		_update_color()

func _init(m: MeshInstance3D) -> void:
	mesh = m

func _update_color():
	var count = mesh.get_surface_override_material_count()
	for i in range(count):
		if not color_override:
			mesh.set_surface_override_material(i, null)
			continue
		
		var mat: BaseMaterial3D = mesh.mesh.surface_get_material(i)
		var override_mat = mat.duplicate()
		mesh.set_surface_override_material(i, override_mat)
		override_mat.albedo_color = albedo
		override_mat.emission = emission
