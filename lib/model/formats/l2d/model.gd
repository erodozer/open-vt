# System for loading models from VTubeStudio's format
# and spawning them into the scene to be managed
extends "../../vt_model.gd"

const Collections = preload("res://lib/utils/collections.gd")

var model: AyagamiModel
var container: Node

var part_settings = {}
var mesh_settings = {}

func _ready() -> void:
	container = preload("./pixel_subviewport.tscn").instantiate()
	add_child(container)

func is_initialized() -> bool:
	return model != null
	
func get_meshes() -> Array:
	return model.get_node("Meshes").get_children()
	
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
	if property.begins_with("modifiers/parts/"):
		var part_name = property.trim_prefix("modifiers/parts/")
		if part_name.ends_with("/opacity"):
			part_name = part_name.trim_suffix("/opacity")
			return model.get("parts/%s" % part_name)
	if property.begins_with("modifiers/meshes/"):
		var parts = property.trim_prefix("modifiers/meshes/").split("/")
		var mesh_name = parts[0]
		var field = parts[1]
		var modifier = mesh_settings.get(mesh_name, {})
		return modifier.get(field, property_get_revert(property))
	return null

func _property_get_revert(property: StringName) -> Variant:
	if property.begins_with("parameters/") or property.begins_with("parts/"):
		return model.property_get_revert(property)
	if property.begins_with("modifiers/meshes/"):
		var parts = property.trim_prefix("modifiers/meshes/").split("/")
		var field = parts[1]
		match field:
			"screen_color":
				return Color.BLACK
			"multiply_color":
				return Color.WHITE
			"color_override":
				return false
			"pinnable":
				return true
			"pinned":
				return null
	return null

func _set(property: StringName, value: Variant) -> bool:
	if property.begins_with("parameters/") or property.begins_with("parts/"):
		if not property.ends_with("/range") and not property.ends_with("/default"):
			model.set(property, value)
		return true
	if property.begins_with("modifiers/meshes"):
		var parts = property.trim_prefix("modifiers/meshes/").split("/")
		var mesh_name = parts[0]
		var field = parts[1]
		var modifier = mesh_settings.get(mesh_name, {})
		var mesh: MeshInstance2D = model.get_node("Meshes/%s" % [mesh_name])
		match field:
			"screen_color":
				modifier.set(field, value)
				mesh.set_instance_shader_parameter("color_screen", value)
			"multiply_color":
				modifier.set(field, value)
				mesh.set_instance_shader_parameter("color_multiply", value)
			"color_override":
				modifier.set(field, value)
				mesh.set_instance_shader_parameter("color_override", value)
			_:
				return false
		mesh_settings.set(mesh_name, modifier)
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
	
	for part in Collections.select(base_properties, "name", RegEx.create_from_string("^parts/")):
		properties.append(part)
	
	for param in Collections.select(base_properties, "name", RegEx.create_from_string("^parameters/")):
		properties.append(param)
		
	for mesh in get_meshes():
		if (mesh as MeshInstance2D).mesh.get_surface_count() <= 0:
			continue
		
		var n = mesh.name
		properties.append({
			"name": "modifiers/meshes/%s/screen_color" % [mesh.name],
			"type": TYPE_COLOR,
			"usage": PropertyUsageFlags.PROPERTY_USAGE_STORAGE | PropertyUsageFlags.PROPERTY_USAGE_EDITOR
		})
		properties.append({
			"name": "modifiers/meshes/%s/multiply_color" % [mesh.name],
			"type": TYPE_COLOR,
			"usage": PropertyUsageFlags.PROPERTY_USAGE_STORAGE | PropertyUsageFlags.PROPERTY_USAGE_EDITOR
		})
		properties.append({
			"name": "modifiers/meshes/%s/color_override" % [mesh.name],
			"type": TYPE_BOOL,
			"usage": PropertyUsageFlags.PROPERTY_USAGE_STORAGE | PropertyUsageFlags.PROPERTY_USAGE_EDITOR
		})
		properties.append({
			"name": "modifiers/meshes/%s/pinnable" % [mesh.name],
			"type": TYPE_BOOL,
			"usage": PropertyUsageFlags.PROPERTY_USAGE_STORAGE | PropertyUsageFlags.PROPERTY_USAGE_EDITOR
		})
		properties.append({
			"name": "modifiers/meshes/%s/pinned" % [mesh.name],
			"type": TYPE_NODE_PATH,
			"usage": PropertyUsageFlags.PROPERTY_USAGE_STORAGE | PropertyUsageFlags.PROPERTY_USAGE_EDITOR
		})
	
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
	
	var vtube_data = Files.read_json(modelmeta.studio_parameters)
	var ovt_data = Files.read_json(modelmeta.openvt_parameters)
	var model_data = Files.read_json(modelmeta.model)
	
	var mesh_details = vtube_data.get("ArtMeshDetails", {})
	for m in get_meshes():
		if (m as MeshInstance2D).mesh.get_surface_count() <= 0:
			continue
		
		set("modifiers/%s/pinnable" % [m.name], m.name not in mesh_details.get("ArtMeshesExcludedFromPinning", []))

		var center = Math.v32xy(Math.centroid(m.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]))
		m.set_meta("centroid", center)
		m.set_meta("start_centroid", center)
					
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
		
