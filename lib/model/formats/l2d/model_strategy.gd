# System for loading models from VTubeStudio's format
# and spawning them into the scene to be managed
extends "../model_strategy.gd"

const Math = preload("res://lib/utils/math.gd")
const Files = preload("res://lib/utils/files.gd")
const Tracker = preload("res://lib/tracking/tracker.gd")

const l2d_shaders: Array[Shader] = [
	preload("res://addons/gd_cubism/res/shader/2d_cubism_norm_add.gdshader"),
	preload("res://addons/gd_cubism/res/shader/2d_cubism_norm_mix.gdshader"),
	preload("res://addons/gd_cubism/res/shader/2d_cubism_norm_mul.gdshader"),
	preload("res://addons/gd_cubism/res/shader/2d_cubism_mask.gdshader"),
]

var live2d_model: GDCubismUserModel
var container: Node

func _ready() -> void:
	container = preload("./pixel_subviewport.tscn").instantiate()
	add_child(container)

func is_initialized() -> bool:
	return live2d_model != null
	
func get_meshes() -> Array:
	if is_initialized():
		return live2d_model.get_meshes()
	return []
	
func get_parameters() -> Dictionary:
	if is_initialized():
		return live2d_model.parameters
	return {}
	
func get_size() -> Vector2:
	return live2d_model.size
	
func get_origin() -> Vector2:
	return live2d_model.origin
	
func _rebuild_l2d(meta: ModelMeta, smoothing: bool, filter: CanvasItem.TextureFilter):
	var reload = is_initialized()
	if reload:
		live2d_model.queue_free()
		live2d_model = null
		await get_tree().process_frame
		
	var loaded_model: GDCubismUserModel
	loaded_model = GDCubismModelLoader.load_model(meta.model, l2d_shaders, true)
	
	await get_tree().process_frame
		
	if loaded_model == null:
		push_error("could not load model %s" % meta.model)
		return false
	
	loaded_model.mask_viewport_size = 2048
	loaded_model.set_process(true)
	
	var p = PackedScene.new()
	if p.pack(loaded_model) != OK:
		return false
	p.take_over_path(meta.model)
	
	live2d_model = loaded_model
	# adjust anchor to be top-left to match godot's control coordinate system
	add_child(live2d_model)
	await get_tree().process_frame # wait for the model to initialize
	
	for m in loaded_model.get_meshes():
		var center = Math.v32xy(Math.centroid(m.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]))
		m.set_meta("centroid", center)
		m.set_meta("start_centroid", center)
	
	var anim_lib = GDCubismMotionLoader.load_motion_library(loaded_model)
	var idle_anim: AnimationPlayer = get_parent().get_idle_animation_player()
	if idle_anim.has_animation_library(""):
		idle_anim.remove_animation_library("") # remove just in case
	idle_anim.add_animation_library("", anim_lib)
	
	# emotion controller
	var expression_library = {}
	for f in Files.walk_files(meta.model.get_base_dir(), "exp3.json"):
		expression_library[f.get_file()] = JSON.parse_string(FileAccess.get_file_as_string(f))

	get_parent().expression_controller.expression_library = expression_library
	
	# add ONE_SHOT animation player
	var os_lib = AnimationLibrary.new()
	for anim in anim_lib.get_animation_list():
		var a = anim_lib.get_animation(anim)
		var os_a = a.duplicate(true)
		os_a.loop_mode = Animation.LOOP_NONE
		os_lib.add_animation(anim, os_a)
	get_parent().get_animation_player().add_animation_library("", os_lib)
	
	var physics = GDCubismEffectPhysics.new()
	loaded_model.add_child(physics)
	physics.name = "Physics"
	
	return true

func load_model():
	var meta: ModelMeta = get_parent().model
	var smoothing = get_parent().smoothing
	var filter = get_parent().filter
	
	var previously_initialized = is_initialized()
	
	if not await _rebuild_l2d(meta, smoothing, filter):
		return false
		
	var vtube_data = Files.read_json(meta.studio_parameters)
	var model_data = Files.read_json(meta.model)
	
	var mesh_details = vtube_data.get("ArtMeshDetails", {})
	for m in get_meshes():
		m.set_meta("pinnable", m.name not in mesh_details.get("ArtMeshesExcludedFromPinning", []))

		var center = Math.v32xy(Math.centroid(m.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]))
		m.set_meta("centroid", center)
		m.set_meta("start_centroid", center)
					
	await get_tree().process_frame
	
	on_filter_update(filter)
	
	position = -live2d_model.size / 2 # align to top-left
	
	return true
	
func apply_parameters(values: Dictionary):
	for p_name in values:
		live2d_model.set(p_name, values.get(p_name, 0.0))
	
func tracking_updated(tracking_data: Dictionary):
	if not get_parent().movement_enabled:
		return
	
	var moved = Vector3(
		Registry.signed_ilerp_input(
			tracking_data.get("FacePositionX", 0),
			"FacePositionX",
		),
		Registry.signed_ilerp_input(
			tracking_data.get("FacePositionY", 0),
			"FacePositionY",
		),
		Registry.signed_ilerp_input(
			tracking_data.get("FacePositionZ", 0),
			"FacePositionZ",
		)
	)
	var movement = moved * get_parent().movement_scale
	scale = Vector2.ONE + (Vector2.ONE * movement.z)
	
func on_filter_update(filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS, smoothing = false):
	for m in get_meshes():
		m.texture_filter = filter
		
	if smoothing and filter == CanvasItem.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS:
		container.model = live2d_model
	else:
		live2d_model.reparent(self, false)
		live2d_model.position = live2d_model.origin
		container.model = null
