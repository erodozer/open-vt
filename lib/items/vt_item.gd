extends "res://lib/vtobject.gd"

const VtModel = preload("res://lib/model/vt_model.gd")
const Math = preload("res://lib/utils/math.gd")

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

@export var model: VtModel
@export var pinned_to: MeshInstance2D
# offset from the centroid of the pinned mesh
var pin_offset: Vector2 = Vector2.ZERO
# vertex state at time of binding
var pin_vertices: Vector3 = Vector3.ZERO
# indices of the triangle to bind to
var pin_indicies: int = -1
var pin_angle: float = 0
var pin_mode = PinMode.CENTROID
var pin_scale: Vector2 = Vector2.ONE

signal pin_changed(mesh: MeshInstance2D)

func _ready():
	# center the item image
	centered = true
	size = get_node("Render").size
	get_node("Render").position = -size / 2
	
	# process_priority = 1

func _process(_delta: float) -> void:
	if pinned_to == null:
		return
	
	# copy transform from model so that items rotate and scale with it
	if pin_mode == PinMode.CENTROID:
		var pin: Vector2 = pinned_to.get_meta("centroid")
		var angle: float = pinned_to.get_meta("angle")
		global_position = model.to_global(pin + pin_offset - model.render.size / 2)
		rotation = model.rotation + angle
	else:
		var _ary = RenderingServer.mesh_surface_get_arrays(pinned_to.mesh, 0)
		var f = _ary[Mesh.ARRAY_INDEX]
		var t = [
			_ary[Mesh.ARRAY_VERTEX][f[pin_indicies]],
			_ary[Mesh.ARRAY_VERTEX][f[pin_indicies+1]],
			_ary[Mesh.ARRAY_VERTEX][f[pin_indicies+2]]
		]
		
		# compare one of the corner angles to the value it was at during attachment to get current morph rotation
		var angle: float = t[0].angle_to_point(t[1])
		rotation = angle - pin_angle
		scale = pin_scale * model.scale
		
		# apply barycentric weights to current vtx positions to get centroid offset
		global_position = pinned_to.to_global(
			t[0] * pin_vertices.x +
			t[1] * pin_vertices.y +
			t[2] * pin_vertices.z
		) - (self.size.rotated(rotation) / 2 * scale)
		
	
	# rotation = -mtx.get_angle()

func _on_drag_released() -> void:
	if not pinnable:
		return
		
	# sample meshes in reverse front to back order
	# whichever we first intersect with becomes the pin target
	var meshes = model.get_meshes()
	meshes.sort_custom(
		func (a, b):
			return a.z_index < b.z_index
	)
		
	var pinned = pinned_to
	pin_vertices = Vector3.ZERO
	for mesh in meshes:
		if not model.pinnable.get(mesh.name, true):
			continue
		if not mesh.visible:
			continue
		
		var c = self.get_global_transform() * (self.size / 2)
		var p = model.to_local(c)
		var _ary = RenderingServer.mesh_surface_get_arrays(mesh.mesh, 0)
		var v = _ary[Mesh.ARRAY_VERTEX]
		var f = _ary[Mesh.ARRAY_INDEX]
		for vtx in range(0, len(f), 3):
			var tri = [v[f[vtx]], v[f[vtx+1]], v[f[vtx+2]]]
			var tri3d = tri.map(Math.v23xy)
			if Geometry2D.point_is_inside_triangle(p, tri[0], tri[1], tri[2]):
				pin_vertices = Geometry3D.get_triangle_barycentric_coords(
					Math.v23xy(p),
					tri3d[0], tri3d[1], tri3d[2]
				)
				pin_angle = tri[0].angle_to_point(tri[1])
				pin_indicies = vtx
				pinned = mesh
				break
	
	pin_mode = PinMode.VERTICES if pin_vertices != Vector3.ZERO else PinMode.CENTROID
				
	if pinned_to != pinned:
		# preserve scale when pinned
		pin_scale = scale / model.scale
		
		pinned_to = pinned
		pin_changed.emit(pinned)
	
func _on_drag_pressed() -> void:
	pinned_to = null
	pin_offset = Vector2.ZERO
	pin_changed.emit(null)
