# System for loading models from VTubeStudio's format
# and spawning them into the scene to be managed
@abstract extends "res://lib/vtobject.gd"

const Files = preload("res://lib/utils/files.gd")
const ExpressionController = preload("./parameters/expression_value_provider.gd")
const Tracker = preload("res://lib/tracking/tracker.gd")
const ModelMeta = preload("./metadata.gd")
const Serializers = preload("res://lib/utils/serializers.gd")

var modelmeta: ModelMeta
@onready var mixer = %Mixer

var motions: Array :
	get():
		var anim = get_animation_player()
		if anim == null:
			return []
		return anim.get_animation_list()

@export var smoothing: bool = false :
	set(v):
		smoothing = v
		_adjust_filter()

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
			
var texture : Texture2D
# item pinning
var rest_anchors: Dictionary = {}

# movement transforms
var movement_enabled: bool = false
var movement_scale: Vector3 = Vector3.ZERO

signal initialized
signal loaded

var _loading = false

signal modifier_updated(field: StringName, new_value: Variant, old_value: Variant)

@abstract func is_initialized()
@abstract func get_meshes() -> Array

@abstract func _build_model()

func is_bound(parameter: Dictionary) -> bool:
	return has_node(parameter.id)

func _load_model():
	_loading = true
	
	if not (await _build_model()):
		queue_free()
		_loading = false
		loaded.emit()
		return 
	
	_load_settings()
	
	_loading = false
	loaded.emit()
	initialized.emit()
	
	BlueprintManager.register_graph(self)
		
@abstract func get_parameters() -> Dictionary
@abstract func get_idle_animation_player() -> AnimationPlayer
@abstract func get_animation_player() -> AnimationPlayer
@abstract func tracking_updated(tracking_data: Dictionary, _delta: float)
func _adjust_filter():
	pass
	
func hydrate(_settings: Dictionary):
	await _load_model()

func load_model_settings(settings: Dictionary):
	self.scale = Vector2.ONE * settings.get("transform", {}).get(
		"scale", 
		clampf(get_viewport_rect().size.y / size.y, 0.001, 2.0)
	)
	self.rotation_degrees = settings.get("transform", {}).get("rotation", 0)
	self.texture_filter = TEXTURE_FILTER_NEAREST_WITH_MIPMAPS_ANISOTROPIC if settings.get("quality", {}).get("filter", "linear") == "nearest" else TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	self.smoothing = settings.get("quality", {}).get("smoothing", false)
		
	self.position = Serializers.Vec2Serializer.from_json(
		settings.get("transform", {}).get("position", {}),
		get_viewport_rect().get_center()
	)
	
func save_model_settings(settings: Dictionary):
	settings.merge({
		"quality": {
			"filter": "nearest" if self.texture_filter != TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC else "linear",
		},
		"transform": {
			"position": Serializers.Vec2Serializer.to_json(self.position),
			"scale": self.scale.x,
			"rotation": self.rotation_degrees
		},
		"graphs": blueprints.reduce(
			func (acc, b):
				acc[b.name] = b.serialize()
				return acc,
			{}
		)
	})

## load open-vt specific settings
func _load_settings():
	var model_preferences = Files.read_json(modelmeta.openvt_parameters)
	load_model_settings(model_preferences)

func save_settings(_settings: Dictionary = {}):
	if not is_initialized():
		return
	
	var model_data = {}
	
	self.save_model_settings(model_data)
	
	Files.write_json(modelmeta.openvt_parameters, model_data)
