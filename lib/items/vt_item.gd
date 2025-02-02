extends "res://lib/vtobject.gd"

const VtModel = preload("res://lib/model/vt_model.gd")
const utils = preload("res://lib/utils.gd")

@export var pinnable: bool
@export var sort_order: int

@export var pinned_to: MeshInstance2D
var pin_offset: Vector2

signal pin_changed(mesh: MeshInstance2D)

func _ready():
	# center the item image
	render.pivot_offset = render.size / 2
	render.position = -render.size / 2

func _process(delta: float) -> void:
	if pinned_to == null:
		return
		
	var pin: Vector2 = pinned_to.get_meta("centroid")
	var angle: float = pinned_to.get_meta("angle")
	var model: Node2D = get_tree().get_first_node_in_group("vtmodel")
	
	# copy transform from model so that items rotate and scale with it
	global_position = model.to_global(pin + pin_offset - model.render.size / 2)
	render.rotation = model.rotation + angle
	render.scale = model.scale
	
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
	for mesh in meshes:
		if not model.pinnable[mesh.name]:
			continue
		if not mesh.visible:
			continue
		
		# adapt the centroid of the item to the mesh coordinate space
		var v = model.to_local(global_position) + (model.render.size / 2)
		var m = mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		if Geometry2D.is_point_in_polygon(v, m):
			closest = mesh
			offset = v - closest.get_meta("centroid")
			print("pinned %s to %s" % [name, mesh.name])
			break
		
	if pinned_to != closest:
		pin_offset = offset
		pinned_to = closest
		pin_changed.emit(closest)

func _on_image_drag_pressed() -> void:
	pinned_to = null
	pin_offset = Vector2.ZERO
	pin_changed.emit(null)
