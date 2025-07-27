# System for loading models from VTubeStudio's format
# and spawning them into the scene to be managed
extends "res://lib/vtobject.gd"

const Files = preload("res://lib/utils/files.gd")
const ModelFormatStrategy = preload("./model_strategy.gd")
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

var _loading = false

func is_initialized():
	return format_strategy != null and format_strategy.is_initialized()

func get_meshes() -> Array:
	if is_initialized():
		return format_strategy.get_meshes()
	return []

func is_bound(parameter: Dictionary) -> bool:
	return has_node(parameter.id)

func _load_model():
	var reload = is_initialized()
	_loading = true
	
	if not (await format_strategy.load_model()):
		queue_free()
		return 
		
	if reload:
		_loading = false
		return
	
	_load_from_vts()
	_load_settings()
	
	size = format_strategy.get_size()
	scale = Vector2.ONE * clamp(get_viewport_rect().size.y / size.y, 0.001, 2.0)
	rotation_degrees = 0
	# pivot_offset = size / 2
	# spawn off screen
	position = -size 
	
	parameters = format_strategy.get_parameters()
	_loading = false
		
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
	# pass forward to any format specific handling
	format_strategy.tracking_updated(tracking_data)
	
func hydrate(settings: Dictionary):
	await _load_model()
	
	reload.connect(
		func ():
			if not _loading:
				_load_model()
	)

## save bidirectional vts compatible settings
func _save_to_vts():
	var vtube_data = Files.read_json(model.studio_parameters)
	# vtube_data["ParameterSettings"] = studio_parameters.map(func (x): return x.serialize())
	vtube_data["ArtMeshDetails"]["ArtMeshesExcludedFromPinning"] = pinnable.keys().filter(func (x): return pinnable[x] == false)
	vtube_data["FileReferences"]["IdleAnimation"] = get_idle_animation_player().current_animation
	
	Files.write_json(model.studio_parameters, vtube_data)
	
## load bidirectional vts compatible settings
func _load_from_vts():
	var vtube_data = JSON.parse_string(FileAccess.get_file_as_string(model.studio_parameters))
	
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

## load open-vt specific settings
func _load_settings():
	var model_preferences = Files.read_json(model.openvt_parameters)
	scale = Vector2.ONE * model_preferences.get("transform", {}).get("scale", 1.0)
	rotation_degrees = model_preferences.get("transform", {}).get("rotation", 0)
	filter = TEXTURE_FILTER_NEAREST if model_preferences.get("quality", {}).get("filter", "linear") == "nearest" else TEXTURE_FILTER_LINEAR
	smoothing = model_preferences.get("quality", {}).get("smooth", false)
	
	var p = model_preferences.get("transform", {}).get("position", get_viewport_rect().get_center())
	p = Vector2(p.x, p.y)
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
	
	_save_to_vts()
	
	var model_data  = {
		"quality": {
			"filter": "nearest" if self.filter != TEXTURE_FILTER_LINEAR else "linear",
			"smooth": smoothing
		},
		"transform": {
			"position": {"x": self.position.x, "y": self.position.y},
			"scale": self.scale.x,
			"rotation": self.rotation_degrees
		}
	}
	for o in get_tree().get_nodes_in_group("persist:model"):
		o.save_settings(model_data)
	Files.write_json(model.openvt_parameters, model_data)
