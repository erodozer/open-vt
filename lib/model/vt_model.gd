# System for loading models from VTubeStudio's format
# and spawning them into the scene to be managed
@abstract extends "res://lib/vtobject.gd"

const Files = preload("res://lib/utils/files.gd")
const ExpressionController = preload("./parameters/expression_value_provider.gd")
const Tracker = preload("res://lib/tracking/tracker.gd")
const ModelMeta = preload("./metadata.gd")
const Serializers = preload("res://lib/utils/serializers.gd")
const Collections = preload("res://lib/utils/collections.gd")
const ModelModifier = preload("./modifier.gd")

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
## dynamic store used for passing named values between blueprints
var store: Dictionary = {}
var _store_changed = false
signal store_changed
			
var texture : Texture2D
# item pinning
var rest_anchors: Dictionary = {}

# movement transforms
var movement_enabled: bool = false
var movement_scale: Vector3 = Vector3.ZERO

signal initialized
signal loaded

var _loading = false

var modifier_map: Dictionary :
	get = get_modifier_map
		
@abstract func get_modifier_map() -> Dictionary

signal modifier_updated(field: StringName, new_value: Variant, old_value: Variant)

@abstract func is_initialized()
@abstract func get_meshes() -> Array

@abstract func _build_model()

func is_bound(parameter: Dictionary) -> bool:
	return has_node(parameter.id)

func _load_model():
	set_process_internal(true)
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
	var serializer = Serializers.ObjSerializer
	model_data["modifiers"] = modifier_map.keys().reduce(
		func (acc, k):
			var group = k
			var modifier_set = modifier_map[k]
			if modifier_set is Dictionary:
				acc[group] = Collections.remap(modifier_set, func (v): return Serializers.ObjSerializer.to_json(v))
			else:
				acc[group] = Serializers.ObjSerializer.to_json(modifier_set)
			return acc,
		{}
	)
	
	self.save_model_settings(model_data)
	
	Files.write_json(modelmeta.openvt_parameters, model_data)

func _get(property: StringName) -> Variant:
	if property.begins_with("modifiers/"):  #ex. modifiers/parts/PART_NAME/color
		property = property.trim_prefix("modifiers/")
		var segments = property.split("/")
		var type = segments[0]
		if type not in modifier_map:
			return null
		var settings: ModelModifier
		var field: String
		if modifier_map[type] is Dictionary:
			var target = segments[1]
			field = segments[2]
			settings = modifier_map[type].get(target)
		else:
			settings = modifier_map[type]
			field = segments[1]
		if not settings:
			return null
		var value = settings.get(field)
		if value == null:
			value = settings.property_get_revert(field)
		return value
	elif property.begins_with("store/"):
		property = property.trim_prefix("store/")
		return store.get(property, 0.0)
	return null

func _property_get_revert(property: StringName) -> Variant:
	if property.begins_with("modifiers/"):  #ex. modifiers/parts/PART_NAME/color
		property = property.trim_prefix("modifiers/")
		var segments = property.split("/")
		var type = segments[0]
		
		if type not in modifier_map:
			return null
		
		var settings: ModelModifier
		var field: String
		if modifier_map[type] is Dictionary:
			var target = segments[1]
			field = segments[2]
			settings = modifier_map[type].get(target)
		else:
			settings = modifier_map[type]
			field = segments[1]
		return settings.property_get_revert(field)
	elif property.begins_with("store/"):
		property = property.trim_prefix("store/")
		if property in store:
			return 0.0
	return null

func _set(property: StringName, value: Variant) -> bool:
	if property.begins_with("modifiers/"):  #ex. modifiers/parts/PART_NAME/color
		property = property.trim_prefix("modifiers/")
		var parts = property.split("/")
		var type = parts[0]
		if type not in modifier_map:
			return false
		
		var modifier: ModelModifier
		var field: String
		if modifier_map[type] is Dictionary:
			var target = parts[1]
			modifier = modifier_map[type][target]
			field = parts[2]
		else:
			modifier = modifier_map[type]
			field = parts[1]
		
		if field not in modifier:
			return false
		
		var old_value = modifier.get(field)
		modifier.set(field, value)
		modifier_updated.emit.call_deferred(
			property, value, old_value
		)
		return true
	elif property.begins_with("store/"):
		property = property.trim_prefix("store/")
		if value == null:
			store.erase(property)
			_store_changed = true
			return true
		elif typeof(value) == TYPE_FLOAT:
			if property not in store:
				_store_changed = true
			store[property] = value 
			return true
	return false

func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []
	
	for prefix in modifier_map:
		var settings = modifier_map[prefix]
		if settings is Dictionary:
			for p in settings:
				var modifier = settings[p]
				for prop in modifier.get_property_list():
					if (prop.usage & PROPERTY_USAGE_STORAGE or prop.usage & PROPERTY_USAGE_READ_ONLY) and not (prop.usage & PROPERTY_USAGE_INTERNAL):
						properties.append({
							"name": "modifiers/{0}/{1}/{2}".format([prefix, p, prop.name]),
							"type": prop.type,
							"hint": prop.hint,
							"hint_string": prop.hint_string,
						})
		else:
			for prop in settings.get_property_list():
				if (prop.usage & PROPERTY_USAGE_STORAGE or prop.usage & PROPERTY_USAGE_READ_ONLY) and not (prop.usage & PROPERTY_USAGE_INTERNAL):
					properties.append({
						"name": "modifiers/{0}/{1}".format([prefix, prop.name]),
						"type": prop.type,
						"hint": prop.hint,
						"hint_string": prop.hint_string,
					})
	
	for key in store:
		properties.append({
			"name": "store/{0}".format([key]),
			"type": TYPE_FLOAT,
			"hint": PROPERTY_HINT_NONE,
			"hint_string": "",
			"usage": PROPERTY_USAGE_SCRIPT_VARIABLE
		})
	
	return properties

func _notification(what: int) -> void:
	if what == NOTIFICATION_INTERNAL_PROCESS:
		if _store_changed:
			_store_changed = false
			store_changed.emit()
