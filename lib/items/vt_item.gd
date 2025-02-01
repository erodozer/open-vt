extends Node2D
		
const PRECISION = 5.0

const VtModel = preload("res://lib/model/vt_model.gd")
const utils = preload("res://lib/utils.gd")

@export var pinnable: bool
@export var sort_order: int

@export var pinned_to: MeshInstance2D
var pin_offset: Vector2

signal pin_changed(mesh: MeshInstance2D)

func _process(delta: float) -> void:
	if pinned_to == null:
		return
		
	var center_point: Vector3 = utils.centroid(pinned_to.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX])
	var pin: Vector3 = pinned_to.get_meta("centroid")
	var mtx = Quaternion(pin, center_point)
	
	global_position = mtx * utils.v23xy(pin_offset)
	rotation = -mtx.get_angle()

func _on_draggable_drag_released():
	print("released " + name)
	if not pinnable:
		return
		
	var model: VtModel = get_tree().get_first_node_in_group("vtmodel")
	var closest: MeshInstance2D
	var dst: float = PRECISION
	for mesh in model.get_meshes():
		var center = utils.v32xy(utils.centroid(mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]) + utils.v23xy(mesh.global_position))
		var mesh_dst = global_position.distance_to(center)
		if mesh_dst <= dst:
			closest = mesh
			dst = mesh_dst
			
	if closest != null:
		pinned_to = closest
		pin_offset = global_position - closest.global_position
		pin_changed.emit(closest)
