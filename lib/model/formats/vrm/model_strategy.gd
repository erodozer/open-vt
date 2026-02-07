extends "../model_strategy.gd"

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
	"neutral"
]

var model: Node3D
var container: SubViewportContainer
var vp: SubViewport
var camera: Camera3D

var blendshapes_meshes = {}

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
	
	gltf.unregister_gltf_document_extension(vrm_extension)
	
	return vrm
	
func load_model():
	var meta: ModelMeta = get_parent().model
	
	model = load_vrm(meta.model)
	await get_tree().process_frame
	
	if model == null:
		return false
	
	# scan through animations to build up blendshape parameters
	# Find all the "rest" values to blend with.
	var anim: AnimationPlayer = model.get_node("AnimationPlayer")
	var parameters = {}
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
				parameters[blend_shape] = {
					"id": blend_shape,
					"name": blend_shape,
					"default": a.track_get_key_value(track_index, 0),
					"min": 0.0,
					"max": 1.0
				}
	_parameters = parameters
	vp.add_child(model)
	
	var aabb: AABB = AABB()
	for c in model.get_node("%GeneralSkeleton").get_children():
		if c is VisualInstance3D:
			aabb = aabb.merge(c.get_aabb())
	
	vp.size = Vector2(
		aabb.size.x * 512.0,
		aabb.size.y * 512.0
	)
	anim.play("RESET")
	
	_meshes = model.find_children("*", "VisualInstance3D")
	
	#camera.look_at(model.position)
	return true
	
func get_size() -> Vector2:
	return vp.size
	
func get_origin() -> Vector2:
	return vp.size / 2.0

var _meshes = []
func get_meshes() -> Array:
	return _meshes
	
var _parameters = {}
func get_parameters() -> Dictionary:
	return _parameters
	
func on_filter_update(filter, smoothing):
	container.texture_filter = filter
	
func tracking_updated(tracking_data: Dictionary):
	pass
	
func apply_parameters(values: Dictionary):
	# transform parameters into VRM blendshapes
	
	for blend_shape in values.keys():
		var value = values.get(blend_shape)
		var path = "blend_shapes/%s" % blend_shape
		var prev = model.get(path)
		model.set(path, value)
