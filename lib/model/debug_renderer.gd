extends Node2D

const utils = preload("res://lib/utils.gd")
const VtModel = preload("res://lib/model/vt_model.gd")

@export var model: VtModel

func _process(delta: float) -> void:
	if not visible:
		return
		
	queue_redraw()
	
func _draw() -> void:
	for m in model.get_meshes():
		if not model.pinnable.get(m.name, false):
			continue
		
		var am: ArrayMesh = m.mesh
		var c: Vector3 = utils.centroid(am.surface_get_arrays(0)[Mesh.ARRAY_VERTEX])
		draw_circle(utils.v32xy(c), 2, Color.BLUE)
