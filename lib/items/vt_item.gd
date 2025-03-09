extends "res://lib/vtobject.gd"

const VtModel = preload("res://lib/model/vt_model.gd")
const utils = preload("res://lib/utils.gd")

# distance from the center of the item to sample for vertices
# assuming this is how VTS is deciding which vertices to bind to
const PIN_RANGE = 50.0

# define the style of pin weight
# when no vertices are in range when binding
# we use an offset relative to the centroid
# otherwise we take the weighted average of the vertices in the
# near vicinity of the center of the item
enum PinMode {
	CENTROID,
	VERTICES
}

@export var pinnable: bool
@export var sort_order: int

@export var pinned_to: MeshInstance2D
# offset from the centroid of the pinned mesh
var pin_offset: Vector2 = Vector2.ZERO
# vertex state at time of binding
var pin_vertices: Array = []
# indices of the vertices to bind to
var pin_indicies: Array = []
var pin_mode = PinMode.CENTROID

signal pin_changed(mesh: MeshInstance2D)

func _ready():
	# center the item image
	pivot_offset = size / 2
	position = -size / 2

func _process(delta: float) -> void:
	if pinned_to == null:
		return
		
	var model: Node2D = get_tree().get_first_node_in_group("vtmodel")
	
	# copy transform from model so that items rotate and scale with it
	if pin_mode == PinMode.CENTROID:
		var pin: Vector2 = pinned_to.get_meta("centroid")
		var angle: float = pinned_to.get_meta("angle")
		global_position = model.to_global(pin + pin_offset - model.render.size / 2)
		rotation = model.rotation + angle
	else:
		# calculate the angle from the vertices
		var vertices = pinned_to.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var rot = Vector2.ZERO
		for id in pin_vertices:
			rot += vertices[id].normalized()
			rot /= 2
		
		rotation = model.rotation + rot.angle()
	scale = model.scale
	
	# rotation = -mtx.get_angle()

func _on_draggable_drag_released():
	print("released " + name)
	if not pinnable:
		return
		
	var model: VtModel = get_tree().get_first_node_in_group("vtmodel")
	var closest: MeshInstance2D
	# sample meshes in reverse front to back order
	# whichever we first intersect with becomes the pin target
	var meshes = model.get_meshes()
	meshes.sort_custom(func (a, b): return a.z_index > b.z_index)
	var offset = Vector2.ZERO
	var pin_vtx = []
	var pin_idx = []
		
	for mesh in meshes:
		if not model.pinnable[mesh.name]:
			continue
		if not mesh.visible:
			continue
		
		# adapt the centroid of the item to the mesh coordinate space
		var v = model.to_local(global_position) + (model.render.size / 2)
		var m = mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		if not Geometry2D.is_point_in_polygon(v, m):
			continue
			
		closest = mesh
		offset = v - closest.get_meta("centroid")
		
		# sample for nearest vertices
		for idx in range(len(m)):
			var dst = v.distance_to(m[idx])
			if abs(dst) <= PIN_RANGE:
				pin_vtx.append(m[idx])
				pin_idx.append(idx)
		
		print("pinned %s to %s" % [name, mesh.name])
		break
	
	pin_offset = offset
	pin_vertices = pin_vtx
	pin_indicies = pin_idx
	pin_mode = PinMode.VERTICES if not pin_vtx.is_empty() else PinMode.CENTROID

	if pinned_to != closest:
		pinned_to = closest
		pin_changed.emit(closest)

func _on_image_drag_pressed() -> void:
	pinned_to = null
	pin_offset = Vector2.ZERO
	pin_changed.emit(null)
