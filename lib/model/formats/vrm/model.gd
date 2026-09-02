extends "../../vt_model.gd"

const VRM_BLENDSHAPES : PackedStringArray = [
	# emotions
	"happy",
	"angry",
	"sad",
	"relaxed",
	"surprised",
	# mouth shapes
	"aa",
	"ee",
	"ih",
	"oh",
	"ou",
	# eyes
	"blinkLeft",
	"blinkRight",
	"lookUp",
	"lookDown",
	"lookLeft",
	"lookRight",
	"neutral",
	# head
	"headRotX",
	"headRotY",
	"headRotZ",
]

var model: Node3D
var container: Node
var vp: SubViewport
var camera: Camera3D

var blendshapes_meshes = {}

var mesh_settings: Dictionary[StringName, ModelModifier] = {}
func get_modifier_map():
	return {
		"meshes": mesh_settings,
	}

func load_data(path: String) -> ModelMeta:
	var model_file: String = ""
	for file in Array(DirAccess.get_files_at(path)):
		if file.ends_with(".vrm"):
			model_file = path.path_join(file)
	
	if model_file.is_empty():
		return null
	
	var meta = ModelMeta.new()
	
	var base_name = ""
	base_name = model_file.get_file()
	meta.name = base_name
	meta.id = base_name
	meta.model = model_file
	meta.path = path
	meta.format = "vrm"
	meta.openvt_parameters = "%s/%s.ovt.json" % [meta.model.get_base_dir(), base_name]
	
	return meta
	
func _ready() -> void:
	container = preload("./model_viewport.tscn").instantiate()
	vp = container.get_node("%SubViewport")
	camera = container.get_node("%Camera3D")
	add_child(container)

func is_initialized():
	return model != null
	
func load_vrm(path: String):
		
	var gltf: GLTFDocument = GLTFDocument.new()
	var vrm_extension: GLTFDocumentExtension = preload("res://addons/vrm/vrm_extension.gd").new()
	gltf.register_gltf_document_extension(vrm_extension, true)
	
	var state: GLTFState = GLTFState.new()
	# state.handle_binary_image = GLTFState.HANDLE_BINARY_EMBED_AS_BASISU

	# Ensure Tangents is required for meshes with blend shapes as of Godot 4.2.
	# EditorSceneFormatImporter.IMPORT_GENERATE_TANGENT_ARRAYS = 8
	# EditorSceneFormatImporter may not be available in release builds, so hardcode 8 for flags
	state.set_additional_data(&"vrm/head_hiding_method", 3)
	state.set_additional_data(&"vrm/first_person_layers", 2)
	state.set_additional_data(&"vrm/third_person_layers", 4)
	
	var err = gltf.append_from_file(path, state, 16 | 8 | 2)
	if err != OK:
		gltf.unregister_gltf_document_extension(vrm_extension)
		return false
	
	var vrm = gltf.generate_scene(state)
	vrm.add_child(XRFaceModifier3D.new())
	vrm.add_child(XRBodyModifier3D.new())
	
	gltf.unregister_gltf_document_extension(vrm_extension)
	
	return vrm
	
func _build_model():
	model = load_vrm(modelmeta.model)
	await get_tree().process_frame
	
	if model == null:
		return false
	
	# scan through animations to build up blendshape parameters
	# Find all the "rest" values to blend with.
	var anim: AnimationPlayer = model.get_node("AnimationPlayer")
	_parameters = {
		# head
		"headRotX": {
			"id": "headRotX",
			"name": "Head Rotation X",
			"default": 0,
			"range": Vector2(-1, 1),
			"value": 0,
		},
		"headRotY": {
			"id": "headRotY",
			"name": "Head Rotation Y",
			"default": 0,
			"range": Vector2(-0.5, 0.5),
			"value": 0,
		},
		"headRotZ": {
			"id": "headRotZ",
			"name": "Head Rotation Z",
			"default": 0,
			"range": Vector2(-0.5, 0.5),
			"value": 0,
		},
	}
	if anim.has_animation("RESET"):
		var a : Animation = anim.get_animation("RESET")
		for track_index in range(0, a.get_track_count()):
			var track_path : NodePath = a.track_get_path(track_index)
			var track_type = a.track_get_type(track_index)
			if a.track_get_type(track_index) == Animation.TYPE_BLEND_SHAPE:
				var blend_shape = track_path.get_subname(0)
				var meshes = blendshapes_meshes.get(blend_shape, [])
				meshes.append(track_path)
				blendshapes_meshes[blend_shape] = meshes
				_parameters[blend_shape] = {
					"id": blend_shape,
					"name": blend_shape,
					"default": a.track_get_key_value(track_index, 0),
					"range": Vector2(0.0, 1.0),
					"value": a.track_get_key_value(track_index, 0)
				}
	vp.add_child(model)
	
	(model.get_node("GeneralSkeleton") as Skeleton3D).reset_bone_poses() # force reset bones
	anim.play("RESET")
	await get_tree().process_frame
	
	_meshes = model.find_children("*", "VisualInstance3D")
	for m in _meshes:
		var modifier = preload("./modifiers/mesh_modifier.gd").new(m)
		mesh_settings[m.name] = modifier
	
	transform_updated.connect(
		func (position, scale, rotation, offset, ypr):
			model.position = camera.project_position(
				position, 3.0
			) - Vector3(0, get_size_3d().size.y * scale.x / 2, 0)
			model.scale = Vector3.ONE * scale.x
			model.rotation = ypr
	)
	
	#camera.look_at(model.position)
	return true
	
func get_size_3d() -> AABB:
	var aabb: AABB = AABB()
	for c in model.get_node("%GeneralSkeleton").get_children():
		if c is VisualInstance3D:
			aabb = aabb.merge(c.get_aabb())
	return aabb
	
func get_size() -> Vector2:
	var aabb = get_size_3d()
	
	var bl = camera.unproject_position(
		aabb.position
	)
	var tr = camera.unproject_position(
		aabb.position + aabb.size
	)
			
	var rect = Rect2i(
		bl.x, tr.y, tr.x - bl.x, bl.y - tr.y
	)
			
	return rect.size
	
func get_origin() -> Vector2:
	return vp.size / 2.0

var _meshes = []
func get_meshes() -> Array:
	return _meshes
	
var _parameters: Dictionary[String, Dictionary] = {}
func get_parameters() -> Dictionary[String, Dictionary]:
	return _parameters
	
func tracking_updated(tracking_data: Dictionary, delta: float):
	pass
	
func apply_parameters(values: Dictionary[String, float]):
	# transform parameters into VRM blendshapes
	for blend_shape in values.keys():
		var blend_meshes = blendshapes_meshes.get(blend_shape, [])
		var weight = values.get(blend_shape, 0.0)
		for path in blend_meshes:
			var m = model.get_node(path)
			m.set("blend_shapes/%s" % blend_shape, weight)
	
func get_texture() -> Texture2D:
	return (container.get_child(0).get_child(0) as SubViewport).get_texture()

func _process(delta: float) -> void:
	# apply composite parameter values to Bones
			
	var target: Transform3D = Transform3D(
		Quaternion(
			_parameters["headRotY"].value,
			_parameters["headRotX"].value,
			_parameters["headRotZ"].value,
			1.0
		)
	)
	var skeleton = (model.get_node("GeneralSkeleton") as Skeleton3D)
	
	var head_bone = skeleton.find_bone("Head")
	var neck_bone = skeleton.get_bone_parent(head_bone)
	var neck_transform: Transform3D = skeleton.global_transform * skeleton.get_bone_global_pose(neck_bone)
	var head_transform: Transform3D = neck_transform.inverse() * target * (
		skeleton.transform * skeleton.get_bone_global_rest(head_bone)
	)
	skeleton.set_bone_pose_rotation(
		head_bone,
		head_transform.basis.get_rotation_quaternion()
	)

func _get(property: StringName) -> Variant:
	if property.begins_with("parameters/"):
		var param = property.trim_prefix("parameters/")
		return _parameters[param]
	return null
	
func _property_get_revert(property: StringName) -> Variant:
	if property.begins_with("parameters/"):
		# transform parameters into VRM blendshapes
		var blend_shape = property.trim_prefix("parameters/")
		if blend_shape not in _parameters:
			return null
		
		return _parameters[blend_shape].default
	
	return null
	
func _set(property: StringName, value: Variant) -> bool:
	if property.begins_with("parameters/"):
		# transform parameters into VRM blendshapes
		var blend_shape = property.trim_prefix("parameters/")
		if blend_shape not in _parameters:
			return false
		
		var blend_meshes = blendshapes_meshes.get(blend_shape, [])
		var weight = value as float
		for path in blend_meshes:
			var m = model.get_node(path)
			m.set("blend_shapes/%s" % blend_shape, weight)
		_parameters[blend_shape].value = weight
		return true
	
	return false

func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []
	
	for key in _parameters:
		var param = _parameters[key]
		properties.append({
			"name": "parameters/{id}".format(param),
			"type": TYPE_FLOAT,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "{min},{max}".format({"min": param.range.x, "max": param.range.y}),
		})

	return properties

func get_idle_animation_player() -> AnimationPlayer:
	return model.get_node("AnimationPlayer")
	
func get_animation_player() -> AnimationPlayer:
	return null
	
func get_expression_controller():
	return null
