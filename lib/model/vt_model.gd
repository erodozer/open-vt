# System for loading models from VTubeStudio's format
# and spawning them into the scene to be managed
extends "res://lib/vtobject.gd"

const utils = preload("res://lib/utils.gd")
const ParameterSetting = preload("res://lib/tracking/parameter_setting.gd")
const ParameterProvider = preload("./parameter_value_provider.gd")
const TrackingSystem = preload("res://lib/tracking_system.gd")
const ModelMeta = preload("./metadata.gd")

static var linear_shaders = [
	preload("res://addons/gd_cubism/res/shader/2d_cubism_norm_add.gdshader"),
	preload("res://lib/model/shaders/linear/2d_cubism_norm_mix.gdshader"),
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
		if live2d_model.get_animations() == null:
			return []
		return live2d_model.get_animations().get_animation_list()

var parameters_l2d: Array
var model_parameters: Dictionary

func get_animation_player():
	return live2d_model.get_node("OneShotMotion")

var filter: CanvasItem.TextureFilter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS :
	set(v):
		filter = v
		if render:
			_load_model(model)
var smoothing: bool = false :
	set(v):
		smoothing = v
		if render:
			_load_model(model)
			
var studio_parameters: Array = []
var parameter_values: Dictionary = {}
var expressions: Array :
	get():
		if live2d_model == null: return []
		return live2d_model.get_expressions()

# item pinning
var pinnable: Dictionary = {}
var rest_anchors: Dictionary = {}

signal initialized

func get_meshes() -> Array:
	if live2d_model != null:
		return live2d_model.get_meshes()
	return []

func is_bound(parameter: Dictionary) -> bool:
	return has_node(parameter.id)

func _ready():
	if model:
		_load_model(model)
		
	var tracking: TrackingSystem = get_tree().get_first_node_in_group("system:tracking")
	tracking.parameters_updated.connect(parameters_updated)
	
func _rebuild_l2d(model: ModelMeta):
	var loaded_model: GDCubismUserModel
	loaded_model = GDCubismModelLoader.load_model(model.model, true, true,
		nearest_shaders if filter == TEXTURE_FILTER_NEAREST else linear_shaders
	)
	var p = PackedScene.new()
	if p.pack(loaded_model) != OK:
		return false
	p.take_over_path(model.model)
	
	if render != null:
		render.queue_free()
		for c in mixer.get_children():
			c.queue_free()
		await get_tree().process_frame
		
	if loaded_model == null:
		push_error("could not load model %s" % model.model)
	
	live2d_model = loaded_model
	
	if smoothing and filter == TEXTURE_FILTER_NEAREST:
		var container = preload("./pixel_subviewport.tscn").instantiate()
		container.model = live2d_model
		render = container
	else:
		render = live2d_model
		
	add_child(render)
	
	var canvas_info = live2d_model.get_canvas_info()
	# adjust anchor to be top-left to match godot's control coordinate system
	live2d_model.position = live2d_model.get_canvas_info().origin_in_pixels
	size = live2d_model.get_canvas_info().size_in_pixels
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
	
	# idle animation, ripped out from the model
	var idle_player = live2d_model.get_animation_player()
	var anim_lib = idle_player.get_animation_library("")
	
	var idle_motion = ParameterProvider.new()
	mixer.add_child(idle_motion)
	idle_motion.name = "IdleMotion"
	idle_player.root_node = idle_player.get_path_to(idle_motion)
	idle_player.active = true
	
	var tracking = ParameterProvider.new()
	mixer.add_child(tracking)
	tracking.name = "Tracking"
	
	# emotion controller
	var emotions = preload("res://lib/model/expression_value_provider.gd").new()
	emotions.name = "Expression"
	mixer.add_child(emotions)
	var emotion_controller = live2d_model.get_expression_controller()
	emotion_controller.set_process(false)
	emotions.expression_controller = emotion_controller
	
	# add ONE_SHOT animation player
	var os_lib = AnimationLibrary.new()
	for anim in anim_lib.get_animation_list():
		var a = anim_lib.get_animation(anim)
		var os_a = a.duplicate(true)
		os_a.loop_mode = Animation.LOOP_NONE
		os_lib.add_animation(anim, os_a)
	var os_ap = AnimationPlayer.new()
	os_ap.name = "OneShotMotion"
	os_ap.add_animation_library("", os_lib)
	live2d_model.add_child(os_ap)
	
	var os_provider = ParameterProvider.new()
	mixer.add_child(os_provider)
	os_provider.name = "OneShotMotion"
	os_ap.set_root(os_ap.get_path_to(os_provider))
	os_ap.animation_finished.connect(
		func ():
			os_provider.reset()
	)
	os_provider.weight = 0
	
	return true

func _load_model(model: ModelMeta):
	if not await _rebuild_l2d(model):
		queue_free()
		return
	
	var vtube_data = JSON.parse_string(FileAccess.get_file_as_string(model.studio_parameters))
	var model_data = JSON.parse_string(FileAccess.get_file_as_string(model.model))
	var display_data = JSON.parse_string(FileAccess.get_file_as_string(model.model_parameters))
	
	var idle_animation = vtube_data["FileReferences"]["IdleAnimation"]
	if idle_animation:
		live2d_model.get_animation_player().play(idle_animation)
	
	for i in live2d_model.get_parameters():
		model_parameters[i] = live2d_model.get_parameters()[i]
	
	studio_parameters.clear()
	for parameter_data in vtube_data["ParameterSettings"]:
		var p = preload("res://lib/tracking/parameter_setting.gd").new()
		var ok = p.deserialize(parameter_data)
		if ok:
			p.model_parameter = model_parameters[p.output_parameter]
			studio_parameters.append(p)
			
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
	
	await get_tree().process_frame
	
	initialized.emit()
	
func add_parameter():
	var p = preload("res://lib/tracking/parameter_setting.gd").new()
	%Parameters.add_child(p)
		
func toggle_expression(expression_name: String, activate: bool = true, duration: float = 1.0):
	if activate:
		live2d_model.get_expression_controller().activate_expression(expression_name, duration)
	else:
		live2d_model.get_expression_controller().deactivate_expression(expression_name, duration)
	
func parameters_updated(tracking_data: Dictionary):
	if not mixer.has_node("Tracking"):
		return
		
	var tracking = mixer.get_node("Tracking")
	for parameter in studio_parameters:
		# skip paramters that haven't been fully configured
		if parameter.output_parameter == null or parameter.model_parameter == null:
			return
		# skip parameters that we do not yet support binding to
		if parameter.input_parameter in tracking_data:
			var raw_value = tracking_data[parameter.input_parameter]
			parameter.value = parameter.scale_value(raw_value)
			tracking.set(parameter.output_parameter, parameter.value)

func _process(delta: float) -> void:
	if model == null:
		return
	
#	for m in get_meshes():
#		var center = utils.v32xy(utils.centroid(m.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]))
#		m.set_meta("centroid", center)
#		m.set_meta("global_centroid", render.global_position + center)
#		m.set_meta("angle", center.angle_to(m.get_meta("start_centroid")))

func hydrate(settings: Dictionary):
	if model == null:
		return
	
	await self.initialized
	var model_preferences = settings.get("model_preferences", {}).get(model.id, {})
	self.filter = model_preferences.get("filter", TEXTURE_FILTER_LINEAR_WITH_MIPMAPS)
	self.scale = model_preferences.get("transform", {}).get("scale", self.scale)
	self.rotation_degrees = model_preferences.get("transform", {}).get("rotation", 0)
	
	var p = model_preferences.get("transform", {}).get("position", get_viewport_rect().get_center() - self.size / 2)
	create_tween().tween_property(
		self, "position", 
		p,
		0.5
	).from(
		p + Vector2(0, get_viewport_rect().size.y)
	).set_trans(Tween.TRANS_CUBIC)

func save_settings(settings: Dictionary):
	if model == null:
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
