# System for loading models from VTubeStudio's format
# and spawning them into the scene to be managed
extends "res://lib/vtobject.gd"

const Files = preload("res://lib/utils/files.gd")
const ModelFormatStrategy = preload("./formats/model_strategy.gd")
const ExpressionController = preload("./parameters/expression_value_provider.gd")
const Tracker = preload("res://lib/tracking/tracker.gd")
const ModelMeta = preload("./metadata.gd")
const Serializers = preload("res://lib/utils/serializers.gd")

var model: ModelMeta
@onready var mixer = %Mixer
@onready var format_strategy: ModelFormatStrategy

var motions: Array :
	get():
		return get_animation_player().get_animation_list()

var filter: CanvasItem.TextureFilter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS :
	set(v):
		filter = v
		if is_initialized():
			format_strategy.on_filter_update(v, smoothing)
			
var smoothing: bool = false :
	set(v):
		smoothing = v
		if is_initialized():
			format_strategy.on_filter_update(filter, v)
			
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

var blueprints: Array :
	get():
		return %Actions.get_children()
	set(graphs):
		for g in graphs:
			if g.get_parent():
				g.reparent(%Actions)
			else:
				%Actions.add_child(g)
			g.visible = false

# item pinning
var rest_anchors: Dictionary = {}

# movement transforms
var movement_enabled: bool = false :
	set(value):
		movement_enabled = value
		
var movement_scale: Vector3 = Vector3.ZERO

signal initialized
signal loaded

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
	_loading = true
	
	if not (await format_strategy.load_model()):
		queue_free()
		_loading = false
		loaded.emit()
		return 
	
	_load_from_vts()
	_load_settings()
	
	size = format_strategy.get_size()
	rotation_degrees = 0
	# pivot_offset = size / 2
	# spawn off screen
	
	parameters = format_strategy.get_parameters()
	_loading = false
	loaded.emit()
		
func toggle_expression(expression_name: String, activate: bool = true, duration: float = 1.0, exclusive: bool = false):
	if expression_name.is_empty():
		expression_controller.clear(duration)
	elif activate:
		if exclusive:
			expression_controller.clear(duration)
		expression_controller.activate_expression(expression_name, duration)
	else:
		expression_controller.deactivate_expression(expression_name, duration)
		
func get_idle_animation_player() -> AnimationPlayer:
	return mixer.get_node("IdleMotion/AnimationPlayer")

func get_animation_player() -> AnimationPlayer:
	return mixer.get_node("OneShotMotion/AnimationPlayer")

func tracking_updated(tracking_data: Dictionary, _delta: float):
	if not is_initialized():
		return
	# pass forward to any format specific handling
	format_strategy.tracking_updated(tracking_data)
	
func hydrate(_settings: Dictionary):
	await _load_model()

## save bidirectional vts compatible settings
func _save_to_vts():
	var vtube_data = Files.read_json(model.studio_parameters)
	# vtube_data["ParameterSettings"] = studio_parameters.map(func (x): return x.serialize())
	vtube_data["ArtMeshDetails"]["ArtMeshesExcludedFromPinning"] = get_meshes().filter(
		func (mesh):
			return mesh.get_meta("pinnable", false) == false
	).map(
		func (mesh):
			return mesh.name
	)
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
	#movement_scale = Vector3(
	#	inverse_lerp(0.0, 10.0, movement_settings.get("X", 0.0)),
	#	inverse_lerp(0.0, 10.0, movement_settings.get("Y", 0.0)),
	#	inverse_lerp(0.0, 10.0, movement_settings.get("Z", 0.0))
	#)
	var pin_settings = vtube_data.get("ArtMeshDetails", {}).get("ArtMeshesExcludedFromPinning", [])
	for mesh in get_meshes():
		var exclude = mesh.name in pin_settings
		mesh.set_meta("pinnable", not exclude)

## load open-vt specific settings
func _load_settings():
	var model_preferences = Files.read_json(model.openvt_parameters)
	scale = Vector2.ONE * model_preferences.get("transform", {}).get(
		"scale", 
		clampf(get_viewport_rect().size.y / size.y, 0.001, 2.0)
	)
	rotation_degrees = model_preferences.get("transform", {}).get("rotation", 0)
	filter = TEXTURE_FILTER_NEAREST_WITH_MIPMAPS if model_preferences.get("quality", {}).get("filter", "linear") == "nearest" else TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	smoothing = model_preferences.get("quality", {}).get("smooth", false)
	
	position = Serializers.Vec2Serializer.from_json(
		model_preferences.get("transform", {}).get("position", {}),
		get_viewport_rect().get_center()
	)

func save_settings(_settings: Dictionary):
	if not is_initialized():
		return
	
	_save_to_vts()
	
	var model_data  = {
		"quality": {
			"filter": "nearest" if self.filter != TEXTURE_FILTER_LINEAR_WITH_MIPMAPS else "linear",
			"smooth": smoothing
		},
		"transform": {
			"position": Serializers.Vec2Serializer.to_json(self.position),
			"scale": self.scale.x,
			"rotation": self.rotation_degrees
		}
	}
	for o in get_tree().get_nodes_in_group("persist:model"):
		o.save_settings(model_data)
	Files.write_json(model.openvt_parameters, model_data)
