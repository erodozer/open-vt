# System for loading models from VTubeStudio's format
# and spawning them into the scene to be managed
extends "res://lib/vtobject.gd"

const utils = preload("res://lib/utils.gd")
const ParameterSetting = preload("res://lib/tracking/parameter_setting.gd")
const ParameterProvider = preload("./parameter_value_provider.gd")
const ExpressionController = preload("./expression_value_provider.gd")
const TrackingSystem = preload("res://lib/tracking/tracking_system.gd")
const Tracker = preload("res://lib/tracking/tracker.gd")
const ModelMeta = preload("./metadata.gd")

static var linear_shaders = [
	preload("res://addons/gd_cubism/res/shader/2d_cubism_norm_add.gdshader"),
	preload("res://addons/gd_cubism/res/shader//2d_cubism_norm_mix.gdshader"),
	preload("res://addons/gd_cubism/res/shader/2d_cubism_norm_mul.gdshader"),

	preload("res://addons/gd_cubism/res/shader/2d_cubism_mask.gdshader"),

	preload("res://addons/gd_cubism/res/shader/2d_cubism_mask_add.gdshader"),
	preload("res://addons/gd_cubism/res/shader/2d_cubism_mask_add_inv.gdshader"),
	preload("res://addons/gd_cubism/res/shader/2d_cubism_mask_mix.gdshader"),
	preload("res://addons/gd_cubism/res/shader/2d_cubism_mask_mix_inv.gdshader"),
	preload("res://addons/gd_cubism/res/shader/2d_cubism_mask_mul.gdshader"),
	preload("res://addons/gd_cubism/res/shader/2d_cubism_mask_mul_inv.gdshader")
]

static var nearest_shaders = [
	preload("res://lib/model/shaders/nearest/2d_cubism_norm_add.gdshader"),
	preload("res://lib/model/shaders/nearest/2d_cubism_norm_mix.gdshader"),
	preload("res://lib/model/shaders/nearest/2d_cubism_norm_mul.gdshader"),

	preload("res://lib/model/shaders/nearest/2d_cubism_mask.gdshader"),

	preload("res://lib/model/shaders/nearest/2d_cubism_mask_add.gdshader"),
	preload("res://lib/model/shaders/nearest/2d_cubism_mask_add_inv.gdshader"),
	preload("res://lib/model/shaders/nearest/2d_cubism_mask_mix.gdshader"),
	preload("res://lib/model/shaders/nearest/2d_cubism_mask_mix_inv.gdshader"),
	preload("res://lib/model/shaders/nearest/2d_cubism_mask_mul.gdshader"),
	preload("res://lib/model/shaders/nearest/2d_cubism_mask_mul_inv.gdshader")
]

var live2d_model: GDCubismUserModel
var render: CanvasItem
var model: ModelMeta
@onready var mixer = $Mixer
var motions: Array :
	get():
		if live2d_model == null:
			return []
		return get_animation_player().get_animation_list()

func get_idle_animation_player() -> AnimationPlayer:
	return mixer.get_node("IdleMotion/AnimationPlayer")

func get_animation_player() -> AnimationPlayer:
	return mixer.get_node("OneShotMotion/AnimationPlayer")

var filter: CanvasItem.TextureFilter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS :
	set(v):
		filter = v
		if is_initialized():
			_load_model(model)
var smoothing: bool = false :
	set(v):
		smoothing = v
		if is_initialized():
			_load_model(model)
			
var mipmaps: bool = false :
	set(v):
		mipmaps = v
		if is_initialized():
			_load_model(model)
			
var studio_parameters: Array = []
var expressions: Array :
	get():
		if live2d_model == null: return []
		return expression_controller.expression_library.keys()
var expression_controller: ExpressionController :
	get():
		return mixer.get_node("Expression")

# item pinning
var pinnable: Dictionary = {}
var rest_anchors: Dictionary = {}

# movement transforms
var movement_enabled: bool = false :
	set(value):
		movement_enabled = value
		if not value and live2d_model != null:
			live2d_model.scale = Vector2.ONE
			live2d_model.position = Vector2(live2d_model.get_origin())
		
var movement_scale: Vector3 = Vector3.ZERO

signal initialized

func is_initialized():
	return render != null

func get_meshes() -> Array:
	if live2d_model != null:
		return live2d_model.get_meshes()
	return []

func is_bound(parameter: Dictionary) -> bool:
	return has_node(parameter.id)

func _ready():
	var tracking: TrackingSystem = get_tree().get_first_node_in_group("system:tracking")
	tracking.parameters_updated.connect(parameters_updated)
	
func _rebuild_l2d(meta: ModelMeta):
	var reload = is_initialized()
	if reload:
		render.queue_free()
		render = null
		live2d_model.queue_free()
		live2d_model = null
		await get_tree().process_frame
		
	var loaded_model: GDCubismUserModel
	loaded_model = GDCubismModelLoader.load_model(
		meta.model, 
		nearest_shaders if filter == TEXTURE_FILTER_NEAREST else linear_shaders,
		false if filter == TEXTURE_FILTER_NEAREST else mipmaps
	)
	
	await get_tree().process_frame
		
	if loaded_model == null:
		push_error("could not load model %s" % meta.model)
		return false
	
	loaded_model.mask_viewport_size = 2048
	
	var p = PackedScene.new()
	if p.pack(loaded_model) != OK:
		return false
	p.take_over_path(meta.model)
	
	live2d_model = loaded_model
	
	if smoothing and filter == TEXTURE_FILTER_NEAREST:
		var container = preload("./pixel_subviewport.tscn").instantiate()
		container.model = live2d_model
		render = container
	else:
		render = live2d_model
		
	add_child(render)
	
	for m in loaded_model.get_meshes():
		m.texture_filter = filter
	
	# adjust anchor to be top-left to match godot's control coordinate system
	live2d_model.position = live2d_model.get_origin()
	
	# adjust positioning when loading a new model
	if not reload:
		size = live2d_model.get_size()
		scale = Vector2.ONE * clamp(get_viewport_rect().size.y / size.y, 0.001, 2.0)
		rotation_degrees = 0
		pivot_offset = size / 2
		# spawn off screen
		position = -size 
	
	for m in loaded_model.get_meshes():
		var center = utils.v32xy(utils.centroid(m.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]))
		m.set_meta("centroid", center)
		m.set_meta("start_centroid", center)
		m.set_meta("global_centroid", render.global_position + center)
	
	var idle_player = AnimationPlayer.new()
	var anim_lib = GDCubismMotionLoader.load_motion_library(loaded_model)
	idle_player.add_animation_library("", anim_lib)
	
	var idle_motion = ParameterProvider.new()
	mixer.add_child(idle_motion)
	idle_motion.add_child(idle_player)
	idle_motion.name = "IdleMotion"
	idle_player.root_node = idle_player.get_path_to(idle_motion)
	idle_player.name = "AnimationPlayer"
	idle_player.active = true
	idle_player.deterministic = true
	
	var tracking = ParameterProvider.new()
	mixer.add_child(tracking)
	tracking.name = "Tracking"
	
	# emotion controller
	var expression_library = {}
	for f in utils.walk_files(meta.model.get_base_dir(), "exp3.json"):
		expression_library[f.get_file()] = JSON.parse_string(FileAccess.get_file_as_string(f))

	var emotions = ExpressionController.new()
	emotions.name = "Expression"
	emotions.expression_library = expression_library
	mixer.add_child(emotions)
	
	# add ONE_SHOT animation player
	var os_lib = AnimationLibrary.new()
	for anim in anim_lib.get_animation_list():
		var a = anim_lib.get_animation(anim)
		var os_a = a.duplicate(true)
		os_a.loop_mode = Animation.LOOP_NONE
		os_lib.add_animation(anim, os_a)
	var os_ap = AnimationPlayer.new()
	os_ap.name = "AnimationPlayer"
	os_ap.add_animation_library("", os_lib)
	
	var os_provider = ParameterProvider.new()
	mixer.add_child(os_provider)
	os_provider.name = "OneShotMotion"
	os_provider.add_child(os_ap)
	os_ap.set_root(os_ap.get_path_to(os_provider))
	os_ap.animation_finished.connect(
		func (_name):
			os_provider.reset()
	)
	os_provider.weight = 0
	
	var breathe = preload("./breathe_value_provider.gd").new()
	mixer.add_child(breathe)
	breathe.name = "Breathe"
	breathe.model = self
	
	var blink = preload("./blink_value_provider.gd").new()
	mixer.add_child(blink)
	blink.name = "Blink"
	blink.model = self
	
	var physics = GDCubismEffectPhysics.new()
	loaded_model.add_child(physics)
	physics.name = "Physics"
	
	
	return true

func _load_model(meta: ModelMeta):
	var previously_initialized = is_initialized()
	var changed = model != meta

	if not await _rebuild_l2d(meta):
		queue_free()
		return
		
	var vtube_data = JSON.parse_string(FileAccess.get_file_as_string(meta.studio_parameters))
	var model_data = JSON.parse_string(FileAccess.get_file_as_string(meta.model))
	
	var idle_animation = vtube_data["FileReferences"]["IdleAnimation"]
	if idle_animation:
		get_idle_animation_player().play(idle_animation)
		
	var movement_settings = vtube_data.get("ModelPositionMovement", {})
	movement_enabled = movement_settings.get("Use", false)
	# vts movement based on 10 = +100% scale
	movement_scale = Vector3(
		inverse_lerp(0.0, 10.0, movement_settings.get("X", 0.0)),
		inverse_lerp(0.0, 10.0, movement_settings.get("Y", 0.0)),
		inverse_lerp(0.0, 10.0, movement_settings.get("Z", 0.0))
	)
	
	var transform = vtube_data.get("SavedModelPosition", {})
	# position = utils.vts_to_world(Vector2(transform.get("Position", {}).get("x", 0.0), transform.get("Position", {}).get("y", 0.0)))
	# position = get_viewport().size / 2
	# scale = Vector2(transform.get("Scale", {}).get("x", 1.0), transform.get("Scale", {}).get("y", 1.0))
	# rotation = transform.get("Rotation", {}).get("z", 0.0)
	
	var mesh_details = vtube_data.get("ArtMeshDetails", {})
	for m in get_meshes():
		pinnable[m.name] = m.name not in mesh_details.get("ArtMeshesExcludedFromPinning", [])
		var center = utils.v32xy(utils.centroid(m.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]))
		m.set_meta("centroid", center)
		m.set_meta("start_centroid", center)
		m.set_meta("global_centroid", render.global_position + center)
	
	if changed or not previously_initialized:
		studio_parameters.clear()
		for parameter_data in vtube_data["ParameterSettings"]:
			var p = preload("res://lib/tracking/parameter_setting.gd").new()
			var ok = p.deserialize(parameter_data)
			if ok:
				p.model_parameter = live2d_model.parameters[p.output_parameter]
				studio_parameters.append(p)
				
	await get_tree().process_frame
	
	initialized.emit()
	
func add_parameter():
	var p = preload("res://lib/tracking/parameter_setting.gd").new()
	%Parameters.add_child(p)
		
func toggle_expression(expression_name: String, activate: bool = true, duration: float = 1.0):
	if expression_name.is_empty():
		expression_controller.clear(duration)
	elif activate:
		expression_controller.activate_expression(expression_name, duration)
	else:
		expression_controller.deactivate_expression(expression_name, duration)
	
func parameters_updated(tracking_data: Dictionary):
	if not mixer.has_node("Tracking"):
		return
		
	var tracking = mixer.get_node("Tracking")
	for parameter in studio_parameters:
		# skip paramters that haven't been fully configured
		if parameter.output_parameter == null or parameter.model_parameter == null:
			return
		# allow tracking sources to provide prescaled/absolute values for parameters
		if parameter.output_parameter in tracking_data:
			var raw_value = tracking_data[parameter.output_parameter]
			tracking.set(parameter.output_parameter, raw_value)
		# also skip parameters that we do not yet support binding to
		elif parameter.input_parameter in tracking_data:
			var raw_value = tracking_data[parameter.input_parameter]
			tracking.set(parameter.output_parameter, parameter.scale_value(raw_value))
			
	if movement_enabled:
		var moved = Vector3(
			Tracker.signed_ilerp_input(
				tracking_data.get(ParameterSetting.TrackingInput.FACE_POSITION_X, 0),
				ParameterSetting.TrackingInput.FACE_POSITION_X
			),
			Tracker.signed_ilerp_input(
				tracking_data.get(ParameterSetting.TrackingInput.FACE_POSITION_Y, 0),
				ParameterSetting.TrackingInput.FACE_POSITION_Y
			),
			Tracker.signed_ilerp_input(
				tracking_data.get(ParameterSetting.TrackingInput.FACE_POSITION_Z, 0),
				ParameterSetting.TrackingInput.FACE_POSITION_Z
			)
		)
		var movement = moved * movement_scale
		live2d_model.scale = Vector2.ONE + (Vector2.ONE * movement.z)
		live2d_model.position = Vector2(live2d_model.size) * utils.v32xy(movement) + Vector2(live2d_model.get_origin())
		

func hydrate(settings: Dictionary):
	var model_preferences = settings.get("model_preferences", {}).get(model.id, {})
	filter = model_preferences.get("filter", TEXTURE_FILTER_LINEAR)
	scale = model_preferences.get("transform", {}).get("scale", self.scale)
	mipmaps = model_preferences.get("mipmaps", true)
	rotation_degrees = model_preferences.get("transform", {}).get("rotation", 0)
	
	_load_model(model)
	
	await self.initialized
	await get_tree().process_frame
	var p = model_preferences.get("transform", {}).get("position", get_viewport_rect().get_center() - (self.size / 2))
	create_tween().tween_property(
		self, "position", 
		p,
		0.5
	).from(
		p + Vector2(0, get_viewport_rect().size.y)
	).set_trans(Tween.TRANS_CUBIC)

func save_settings(settings: Dictionary):
	if not is_initialized():
		return
		
	var p = settings.get("model_preferences", {})
	p[model.id] = {
		"filter": self.filter,
		"transform": {
			"position": self.position,
			"scale": self.scale,
			"rotation": self.rotation_degrees
		}
	}
	settings["model_preferences"] = p
	
	# save back updated parameters to VTS configuration	
	var vtube_data = JSON.parse_string(FileAccess.get_file_as_string(model.studio_parameters))
	var f = FileAccess.open(model.studio_parameters, FileAccess.WRITE)
	vtube_data["ParameterSettings"] = studio_parameters.map(func (x): return x.serialize())
	vtube_data["ArtMeshDetails"]["ArtMeshesExcludedFromPinning"] = pinnable.keys().filter(func (x): return pinnable[x] == false)
	vtube_data["FileReferences"]["IdleAnimation"] = get_idle_animation_player().current_animation
	
	var out = JSON.stringify(vtube_data, "  ")
	f.store_string(out)
	f.close()
	
