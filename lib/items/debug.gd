extends Node2D

const VtModel = preload("res://lib/model/vt_model.gd")
const VtItem = preload("res://lib/items/vt_item.gd")

@onready var item = get_parent()

func _process(delta: float) -> void:
	if visible:
		return
		
	queue_redraw()

func _mesh_to_local(point: Vector2):
	var mesh: MeshInstance2D = item.pinned_to
	# position within viewport
	var p = mesh.get_viewport().get_screen_transform() * mesh.get_global_transform_with_canvas() * point
	p = self.get_viewport().get_screen_transform().affine_inverse() * p
	p = to_local(p)
	return p
	
func _draw() -> void:
	var centroid = item.size / 2
	draw_circle(centroid, 2, Color.RED, true, -1.0, true)

	if item.pin_mode == VtItem.PinMode.VERTICES and item.pinned_to != null:
		var _ary = RenderingServer.mesh_surface_get_arrays(item.pinned_to.mesh, 0)
		var f = _ary[Mesh.ARRAY_INDEX]
		for i in range(0, len(f), 3):
			var t = [
				_ary[Mesh.ARRAY_VERTEX][f[i]],
				_ary[Mesh.ARRAY_VERTEX][f[i+1]],
				_ary[Mesh.ARRAY_VERTEX][f[i+2]],
				_ary[Mesh.ARRAY_VERTEX][f[i]]
			].map(_mesh_to_local)
			draw_polyline(t, Color.GREEN if not i == item.pin_indicies else Color.RED)

		var i = item.pin_indicies
		var t = [
			_ary[Mesh.ARRAY_VERTEX][f[i]],
			_ary[Mesh.ARRAY_VERTEX][f[i+1]],
			_ary[Mesh.ARRAY_VERTEX][f[i+2]],
			_ary[Mesh.ARRAY_VERTEX][f[i]]
		].map(_mesh_to_local)
		draw_polyline(t, Color.RED)
