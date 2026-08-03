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
	
func _get(property: StringName) -> Variant:
	if property.begins_with("parameters/"):
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
	if property.begins_with("parameters/"):
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
	if property.begins_with("parameters/"):
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
		if value == CanvasItem.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS:
			container.model = model
		else:
			model.reparent(self, false)
			model.position = model.origin
			container.model = null
		return true
	return false
		
func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []
	var base_properties = model.get_property_list()
	
	var parts = Collections.extract_property_name(base_properties, "parts/")
	for part in parts:
		properties.append({
			"name": "modifiers/parts/%s/opacity",
			"type": TYPE_FLOAT,
			"hint": PropertyHint.PROPERTY_HINT_NONE,
			"hint_string": "rgba",
			"usage": PropertyUsageFlags.PROPERTY_USAGE_STORAGE | PropertyUsageFlags.PROPERTY_USAGE_EDITOR
		})
	
	for mesh in get_meshes():
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
		
	properties.append_array(base_properties)
	
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
		var center = Math.v32xy(Math.centroid(m.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]))
		m.set_meta("centroid", center)
		m.set_meta("start_centroid", center)
	
	var anim_lib = AyagamiLoader.load_motion_library(model)
	var idle_anim: AnimationPlayer = model.get_node("MotionController")
	if idle_anim.has_animation_library(""):
		idle_anim.remove_animation_library("") # remove just in case
	idle_anim.add_animation_library("", anim_lib)
	
	# emotion controller
	#var expression_library = AyagamiLoader.load_expression_library(modelmeta.model.get_base_dir())
	var expression_controller: AyagamiExpressionMutator = model.get_node("ExpressionController")
	#expression_controller.expressions = expression_library
	
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
	#model.add_child(one_shot)
	
	#var physics = GDCubismEffectPhysics.new()
	#loaded_model.add_child(physics)
	#physics.name = "Physics"
	
	var vtube_data = Files.read_json(modelmeta.studio_parameters)
	var model_data = Files.read_json(modelmeta.model)
	
	var mesh_details = vtube_data.get("ArtMeshDetails", {})
	for m in get_meshes():
		set("modifiers/%s/pinnable" % [m.name], m.name not in mesh_details.get("ArtMeshesExcludedFromPinning", []))

		var center = Math.v32xy(Math.centroid(m.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]))
		m.set_meta("centroid", center)
		m.set_meta("start_centroid", center)
					
	await get_tree().process_frame
	
	on_filter_update(filter)
	
	position = -model.size / 2 # align to top-left
	size = model.size
			
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
	scale = Vector2.ONE + (Vector2.ONE * movement.z)
	
func on_filter_update(filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS, smoothing = false):
	model.texture_filter = filter
		
	if smoothing and filter == CanvasItem.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS:
		container.model = model
	else:
		model.reparent(self, false)
		model.position = Vector2.ZERO
		container.model = null

func get_texture() -> Texture2D:
	if container is SubViewportContainer:
		return (container.get_child(0) as SubViewport).get_texture()
	return null
	
func get_idle_animation_player() -> AnimationPlayer:
	return model.get_node("MotionController")
	
func get_animation_player() -> AnimationPlayer:
	return model.get_node("OneshotMotionController")
	
