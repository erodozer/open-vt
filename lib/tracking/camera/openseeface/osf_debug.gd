extends Control

const OpenSeeData = preload("./osf_data.gd")

@export var mirror = false

var mat: BaseMaterial3D
var mesh: ImmediateMesh

func _ready():
	mat = StandardMaterial3D.new()
	mat.use_point_size = true
	mat.point_size = 5.0
	mesh = ImmediateMesh.new()
	%FaceMesh.mesh = mesh

func _on_data_received(data: OpenSeeData) -> void:
	# draw gaze from points 68 (right eye) and 69 (left eye)
	var t = Transform3D(
		Basis(data.rawQuaternion * Quaternion(Vector3.FORWARD, PI/2)),
		Vector3.ZERO
	)
	
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_POINTS, mat)
	for idx in range(len(data.points3D)):
		var point = data.points3D[idx]
		if idx == OpenSeeData.RIGHT_EYE_CENTER:
			point -= Vector3.FORWARD * data.rightGaze
			mesh.surface_set_color(Color.RED)
		elif idx == OpenSeeData.LEFT_EYE_CENTER:
			point -= Vector3.FORWARD * data.leftGaze
			mesh.surface_set_color(Color.RED)
		else:
			mesh.surface_set_color(Color.GREEN)
		mesh.surface_add_vertex(point * Vector3(1, -1, 1) * t)
	mesh.surface_end()
