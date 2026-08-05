# System for loading models from VTubeStudio's format
# and spawning them into the scene to be managed
extends "../../vt_model.gd"

const Collections = preload("res://lib/utils/collections.gd")

var model: AyagamiModel
var container: Node

const ModelModifier = preload("../../modifier.gd")
const ParameterModifier = preload("./modifiers/parameter_modifier.gd")
const PartModifier = preload("./modifiers/part_modifier.gd")
const MeshModifier = preload("./modifiers/mesh_modifier.gd")

var param_settings: Dictionary[StringName, ModelModifier] = {}
var part_settings: Dictionary[StringName, ModelModifier] = {}
var mesh_settings: Dictionary[StringName, ModelModifier] = {}
var modifier_map = {
	"modifiers/parts/": part_settings,
	"modifiers/meshes/": mesh_settings,
	"modifiers/parameters/": param_settings
}

func _ready() -> void:
	container = preload("./pixel_subviewport.tscn").instantiate()
	add_child(container)

func is_initialized() -> bool:
	return model != null
	
func get_meshes() -> Array:
	return model.get_node("Meshes").get_children()
	
func get_parts() -> Array:
	return model.get_parts()
	
func get_size() -> Vector2:
	return model.size
	
func get_origin() -> Vector2:
	return model.origin
	
func get_parameters() -> Dictionary:
	return model.get_parameters().reduce(
		func (acc, p):
			acc[p] = {
				"default": model.get("parameters/%s/default" % p),
				"range": model.get("parameters/%s/range" % p) 
			}
			return acc,
		{}
	)
	
func _get(property: StringName) -> Variant:
	if property.begins_with("parameters/") or property.begins_with("parts/"):
		return model.get(property)
	for prefix in modifier_map:
		if not property.begins_with(prefix):
			continue
		var modifiers = modifier_map[prefix]
		var segments = property.trim_prefix(prefix).split("/")
		var part = segments[0]
		var field = segments[1]
		var modifier: ModelModifier = modifiers.get(part)
		if modifier:
			return modifier.get(field)
	return null

func _property_get_revert(property: StringName) -> Variant:
	if property.begins_with("parameters/") or property.begins_with("parts/"):
		return model.property_get_revert(property)
	
	for prefix in modifier_map:
		if not property.begins_with(prefix):
			continue
		
		var segments = property.trim_prefix(prefix).split("/")
		var part = segments[0]
		var field = segments[1]
		
		var settings: ModelModifier = modifier_map[prefix][part]
		return settings.property_get_revert(field)
		
	return null

func _set(property: StringName, value: Variant) -> bool:
	if property.begins_with("parameters/"):
		if not property.ends_with("/range") and not property.ends_with("/default"):
			model.set(property, value)
			return true
	
	for p in modifier_map:
		if not property.begins_with(p):
			continue
		var parts = property.trim_prefix(p).split("/")
		var param = parts[0]
		var field = parts[1]
		var modifier: ModelModifier = modifier_map[p].get(param)
		if modifier:
			var old_value = modifier.get(field)
			modifier.set(field, value)
			modifier_updated.emit.call_deferred(
				property, value, old_value
			)
			return true

	if property == "texture_filter":
		texture_filter = value
		_adjust_filter()
		return true

	return false
		
func _adjust_filter():
	if texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS_ANISOTROPIC and smoothing:
		container.model = model
	else:
		model.reparent(self, false)
		container.model = null
		
func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []
	var base_properties = model.get_property_list()
	
	for param in Collections.select(base_properties, "name", RegEx.create_from_string("^parameters/")):
		var p_name = param.name.trim_prefix("parameters/")
		properties.append(param)
	
	for prefix in modifier_map:
		var settings = modifier_map[prefix]
		for p in settings:
			var modifier = settings[p]
			for prop in modifier.get_property_list():
				properties.append(prop.merged({
					"name": "{0}{1}/{2}".format([prefix, p, prop.name])
				}, true))
	
	return properties
	
func _build_model():
	var reload = is_initialized()
	if reload:
		model.queue_free()
		model = null
		await get_tree().process_frame
		
	print_debug("loading model from %s" % modelmeta.model)
	model = AyagamiLoader.load_model(modelmeta.model)
	if model == null:
		push_error("could not load model %s" % modelmeta.model)
		return false
	# adjust anchor to be top-left to match godot's control coordinate system
	add_child(model)
	await get_tree().process_frame # wait for the model to initialize
	
	for m in get_meshes():
		if (m as MeshInstance2D).mesh.get_surface_count() <= 0:
			continue
		var center = Math.v32xy(Math.centroid(m.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]))
		m.set_meta("centroid", center)
		m.set_meta("start_centroid", center)
	
	var anim_lib = AyagamiLoader.load_motion_library(model)
	var idle_anim: AnimationPlayer = model.get_node("MotionController")
	if idle_anim.has_animation_library(""):
		idle_anim.remove_animation_library("") # remove just in case
	idle_anim.add_animation_library("", anim_lib)
	
	# emotion controller
	var expression_library = AyagamiLoader.load_expression_library(modelmeta.model.get_base_dir())
	var expression_controller: AyagamiExpressionMutator = model.get_node("ExpressionController")
	expression_controller.expressions = expression_library.keys()
	for e in expression_library.keys():
		var group = expression_library[e]
		if group != "":
			expression_controller.set("expression_groups/%s" % e.get_name(), group)
	
	# add ONE_SHOT animation player
	var os_lib = AnimationLibrary.new()
	for anim in anim_lib.get_animation_list():
		var a = anim_lib.get_animation(anim)
		var os_a = a.duplicate(true)
		os_a.loop_mode = Animation.LOOP_NONE
		os_lib.add_animation(anim, os_a)
	var one_shot = AyagamiMotionMutator.new()
	one_shot.add_animation_library("", os_lib)
	one_shot.name = "OneshotMotionController"
	model.add_child(one_shot)
	
	#var physics = GDCubismEffectPhysics.new()
	#loaded_model.add_child(physics)
	#physics.name = "Physics"
	
	for m in get_meshes():
		if (m as MeshInstance2D).mesh.get_surface_count() <= 0:
			continue
		
		var center = Math.v32xy(Math.centroid(m.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]))
		m.set_meta("centroid", center)
		m.set_meta("start_centroid", center)
		
		mesh_settings[m.name] = MeshModifier.new(m)
		
	for p in get_parameters():
		param_settings[p] = ParameterModifier.new()
	
	for p in get_parts():
		part_settings[p] = PartModifier.new(self, p)
					
	await get_tree().process_frame
	
	model.position = Vector2.ZERO
	size = model.size
	centered = true
			
	return true

func apply_parameters(values: Dictionary):
	for p_name in values:
		model.set(p_name, values.get(p_name, 0.0))
	
func tracking_updated(tracking_data: Dictionary, _delta: float):
	if not movement_enabled:
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
	var movement = moved * movement_scale
	model.scale = Vector2.ONE + (Vector2.ONE * movement.z)

func get_texture() -> Texture2D:
	if container is SubViewportContainer:
		return (container.get_child(0) as SubViewport).get_texture()
	return null
	
func get_idle_animation_player() -> AnimationPlayer:
	return model.get_node("MotionController")
	
func get_animation_player() -> AnimationPlayer:
	return model.get_node("OneshotMotionController")
	
func get_expression_controller() -> AyagamiExpressionMutator:
	return model.get_node("ExpressionController")

func toggle_expression(expression_name: String, activate: bool = true, duration: float = 1.0, exclusive: bool = false):
	var expression_controller = get_expression_controller()
	if expression_controller == null:
		return
	if expression_name.is_empty():
		expression_controller.reset()
	elif activate:
		expression_controller.set("active/%s" % expression_name, true)
	else:
		expression_controller.set("active/%s" % expression_name, false)
		

## save bidirectional vts compatible settings
func _save_to_vts():
	if modelmeta.studio_parameters.is_empty():
		return
	
	var vtube_data = Files.read_json(modelmeta.studio_parameters)
	# vtube_data["ParameterSettings"] = studio_parameters.map(func (x): return x.serialize())
	vtube_data["ArtMeshDetails"]["ArtMeshesExcludedFromPinning"] = get_meshes().reduce(
		func (acc, mesh):
			if mesh.name not in mesh_settings:
				return acc
			var pinnable = get("modifiers/meshes/%s/pinnable" % mesh.name)
			if pinnable:
				acc.append(mesh.name)
			return acc,
		[]
	)
	vtube_data["ArtMeshDetails"]["ArtMeshMultiplyAndScreenColors"] = get_meshes().reduce(
		func (acc, mesh):
			if mesh.name not in mesh_settings:
				return acc
			var override = get("modifiers/meshes/%s/color_override" % mesh.name)
			if override:
				acc.append({
					"ID": mesh.name,
					"Value": "%s|%s" % [
						(get("modifiers/meshes/%s/multiply_color" % mesh.name) as Color).to_html(true),
						(get("modifiers/meshes/%s/screen_color" % mesh.name) as Color).to_html(true),
					]
				})
			return acc,
		[]
	)
	vtube_data["FileReferences"]["IdleAnimation"] = get_idle_animation_player().current_animation
	
	Files.write_json(modelmeta.studio_parameters, vtube_data)
	
## load bidirectional vts compatible settings
func _load_from_vts():
	if modelmeta.studio_parameters.is_empty():
		return
	
	var vtube_data = JSON.parse_string(FileAccess.get_file_as_string(modelmeta.studio_parameters))
	
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

	var mesh_details = vtube_data.get("ArtMeshDetails", {})
	var pin_settings = mesh_details.get("ArtMeshesExcludedFromPinning", [])
		
	# color settings
	var tint = {}
	for v in mesh_details.get("ArtMeshMultiplyAndScreenColors", []):
		var colors = v.Value.split("|")
		tint[v.ID] = {
			"multiply": Color(colors[0]),
			"screen": Color(colors[1])
		}
	
	for mesh in get_meshes():
		if name not in mesh_settings:
			continue
		var settings = mesh_settings[mesh]
		var exclude = mesh.name in pin_settings
		settings.pinnable = not exclude
		
		settings.color_override = mesh.name in tint
		if mesh.name in tint:
			var colors = tint[mesh.name]
			settings.multiply_color = colors.multiply
			settings.screen_color = colors.creen

func save_model_settings(settings: Dictionary):
	super.save_model_settings(settings)
	
	var serializer = Serializers.ObjSerializer
	settings["modifiers"] = {
		"parameters": Collections.remap(param_settings, func (v): return Serializers.ObjSerializer.to_json(v)),
		"meshes": Collections.remap(mesh_settings, func (v): return Serializers.ObjSerializer.to_json(v)),
		"parts": Collections.remap(part_settings, func (v): return Serializers.ObjSerializer.to_json(v))
	}
	
	_save_to_vts()
	
func load_model_settings(settings: Dictionary):
	_load_from_vts()
	super.load_model_settings(settings)

	for p in self.get_parameters():
		var modifier = param_settings[StringName(p)]
		var saved = settings.get("modifiers", {}).get("parameters", {}).get(p, {})
		Serializers.ObjSerializer.from_json(saved, modifier)
	
	for m in self.get_meshes():
		if m.name not in mesh_settings:
			continue
		var modifier = mesh_settings[m.name]
		var saved = settings.get("modifiers", {}).get("meshes", {}).get(m.name, {})
		# fallback to what's loaded from vts
		Serializers.ObjSerializer.from_json(saved, modifier)
		
	for p in self.get_parts():
		var modifier = part_settings[p]
		var saved = settings.get("modifiers", {}).get("parts", {}).get(p, {})
		Serializers.ObjSerializer.from_json(saved, modifier)
	
