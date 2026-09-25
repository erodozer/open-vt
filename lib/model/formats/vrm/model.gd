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

var skeleton: Skeleton3D
var face_tracker = AnimationTree.new()
var body_tracker = XRBodyModifier3D.new()

@onready var model_settings: ModelModifier = preload("./modifiers/base_modifier.gd").new(self)
var mesh_settings: Dictionary[StringName, ModelModifier] = {}
var bone_settings: Dictionary[StringName, ModelModifier] = {}

func get_modifier_map():
	return {
		"model": model_settings,
		"meshes": mesh_settings,
		"bones": bone_settings,
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
	vrm.get_node("GeneralSkeleton").add_child(body_tracker)
	vrm.add_child(face_tracker)
	
	gltf.unregister_gltf_document_extension(vrm_extension)
	
	return vrm
	
func _build_model():
	#debug = true
	centered = true
	is_3D = true
	model = load_vrm(modelmeta.model)
	await get_tree().process_frame
	
	if model == null:
		return false
	
	# scan through animations to build up blendshape parameters
	# Find all the "rest" values to blend with.
	var anim: AnimationPlayer = model.get_node("AnimationPlayer")
	_parameters = {}
	add_child(model)
	
	skeleton = model.get_node("GeneralSkeleton")
	skeleton.reset_bone_poses() # force reset bones
	
	var tree_root = AnimationNodeBlendTree.new()
	face_tracker.anim_player = face_tracker.get_path_to(anim)
	face_tracker.tree_root = tree_root
	
#region build animation tree
	var reset_node = AnimationNodeAnimation.new()
	reset_node.set_animation("RESET")
	tree_root.add_node("RESET", reset_node, Vector2(0, 0))
	
	var last_anim = "RESET"
	for anim_name in anim.get_animation_list():
		if anim_name == "RESET":
			continue
		_parameters[anim_name] = {
			"id": anim_name,
			"name": anim_name.to_pascal_case(),
			"default": 0.0,
			"range": Vector2(0, 1),
			"value": 0.0
		}
		var anim_node = AnimationNodeAnimation.new()
		var anim_node_name = "%s_animation" % anim_name
		anim_node.set_animation(anim_name)
		tree_root.add_node(anim_node_name, anim_node)
		
		var blend_node = AnimationNodeAdd2.new()
		var blend_name = anim_name
		tree_root.add_node(blend_name, blend_node)
		tree_root.connect_node(blend_name, 0, last_anim)
		tree_root.connect_node(blend_name, 1, anim_node_name)
		
		last_anim = blend_name
	tree_root.connect_node("output", 0, last_anim)
#endregion

	_meshes = model.find_children("*", "VisualInstance3D")
	for m in _meshes:
		var modifier = preload("./modifiers/mesh_modifier.gd").new(m)
		mesh_settings[m.name] = modifier
	
	for i in range(skeleton.get_bone_count()):
		var modifier = preload("./modifiers/bone_modifier.gd").new(skeleton, i)
		var bone = skeleton.get_bone_name(i)
		bone_settings[bone] = modifier
	
	var skeleton_bounds = Math.get_spatial_bounds(skeleton)
	skeleton.position.y = -skeleton_bounds.size.y / 2.0
	
	transform_updated.connect(
		func (position, scale, rotation, offset, pyr):
			var camera = get_viewport().get_camera_3d()
			model.rotation = pyr
			model.scale = Vector3.ONE * scale.x
			model.position = camera.project_position(position, 3.0)
			size = get_size()
	)
	
	notify_transform_updated.call_deferred()
	set_process_internal(true)
	
	return true
	
func get_size() -> Vector2:
	var camera = get_viewport().get_camera_3d()
	
	var aabb = Math.get_spatial_bounds(model)
	if not aabb.is_finite():
		return Vector2.ONE
	
	var rect = range(7).reduce(
		func (dim, idx):
			var v = aabb.get_endpoint(idx)
			var px = camera.unproject_position(v)
			if not dim:
				dim.position = px
				return dim
			return dim.expand(px),
		Rect2()
	)
	
	return rect.size / self.scale
	
func get_origin() -> Vector2:
	return size / 2.0

var _meshes = []
func get_meshes() -> Array:
	return _meshes
	
var _parameters: Dictionary[String, Dictionary] = {}
func get_parameters() -> Dictionary[String, Dictionary]:
	return _parameters
	
func tracking_updated(tracking_data: Dictionary, delta: float):
	pass
	
func apply_parameters(values: Dictionary[String, float]):
	pass
	
func get_texture() -> Texture2D:
	return null

func _get(property: StringName) -> Variant:
	if property.begins_with("parameters/"):
		var param = property.trim_prefix("parameters/")
		var data = _parameters.get(param, {})
		return data.get("value", 0.0)
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
		
		var param = _parameters.get(blend_shape)
		var blend = clamp(value, param.range.x, param.range.y)
		face_tracker.set(
			"parameters/%s/add_amount" % blend_shape,
			blend
		)
		_parameters[blend_shape].value = blend
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
