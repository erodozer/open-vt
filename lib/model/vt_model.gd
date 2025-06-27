# System for loading models from VTubeStudio's format
# and spawning them into the scene to be managed
extends "res://lib/vtobject.gd"
class_name VtModel

const utils = preload("res://lib/utils.gd")
const ModelFormatStrategy = preload("./model_strategy.gd")
const ParameterSetting = preload("res://lib/tracking/parameter_setting.gd")
const ExpressionController = preload("./parameters/expression_value_provider.gd")
const Tracker = preload("res://lib/tracking/tracker.gd")
const ModelMeta = preload("./metadata.gd")

var model: ModelMeta
@onready var mixer = %Mixer
@onready var format_strategy: ModelFormatStrategy

var motions: Array :
	get():
		return get_animation_player().get_animation_list()

var filter: CanvasItem.TextureFilter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS :
	set(v):
		filter = v
		reload.emit()
			
var smoothing: bool = false :
	set(v):
		smoothing = v
		reload.emit()
			
var mipmaps: bool = false :
	set(v):
		mipmaps = v
		
var studio_parameters: Array = []
var parameters: Dictionary :
	get():
		if is_initialized():
			return format_strategy.get_parameters()
		return {}
	set(values):
		if is_initialized():
			format_strategy.apply_parameters(values)
		
var expressions: Array :
	get():
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
		
var movement_scale: Vector3 = Vector3.ZERO

signal initialized
signal reload

func is_initialized():
	return format_strategy != null and format_strategy.is_initialized()

func get_meshes() -> Array:
	return format_strategy.get_meshes()

func is_bound(parameter: Dictionary) -> bool:
	return has_node(parameter.id)

func _load_model():
	var reload = is_initialized()
	
	if not (await format_strategy.load_model()):
		queue_free()
		return 
		
	if reload:
		return
	
	var vtube_data = JSON.parse_string(FileAccess.get_file_as_string(model.studio_parameters))
	var model_data = JSON.parse_string(FileAccess.get_file_as_string(model.model))
	
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
	
	size = format_strategy.get_size()
	scale = Vector2.ONE * clamp(get_viewport_rect().size.y / size.y, 0.001, 2.0)
	rotation_degrees = 0
	pivot_offset = size / 2
	# spawn off screen
	position = -size 
	
	studio_parameters.clear()
	for parameter_data in vtube_data["ParameterSettings"]:
		var p = preload("res://lib/tracking/parameter_setting.gd").new()
		var ok = p.deserialize(parameter_data)
		if ok:
			p.model_parameter = self.parameters[p.output_parameter]
			studio_parameters.append(p)

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
		
func get_idle_animation_player() -> AnimationPlayer:
	return mixer.get_node("IdleMotion/AnimationPlayer")

func get_animation_player() -> AnimationPlayer:
	return mixer.get_node("OneShotMotion/AnimationPlayer")

func tracking_updated(tracking_data: Dictionary):
	if not is_initialized():
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
		
	# pass forward to any format specific handling
	format_strategy.tracking_updated(tracking_data)

func hydrate(settings: Dictionary):
	var model_preferences = settings.get("model_preferences", {}).get(model.id, {})
	scale = model_preferences.get("transform", {}).get("scale", self.scale)
	rotation_degrees = model_preferences.get("transform", {}).get("rotation", 0)
	
	_load_model()
	
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
	
