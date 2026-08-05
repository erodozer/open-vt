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
	
	_load_from_vts()
	_load_settings()
	
	_loading = false
	loaded.emit()
	initialized.emit()
	
	BlueprintManager.register_graph(self)
		
@abstract func get_idle_animation_player() -> AnimationPlayer
@abstract func get_animation_player() -> AnimationPlayer
@abstract func tracking_updated(tracking_data: Dictionary, _delta: float)
func _adjust_filter():
	pass
	
func hydrate(_settings: Dictionary):
	await _load_model()

## save bidirectional vts compatible settings
func _save_to_vts():
	if modelmeta.studio_parameters.is_empty():
		return
	
	var vtube_data = Files.read_json(modelmeta.studio_parameters)
	# vtube_data["ParameterSettings"] = studio_parameters.map(func (x): return x.serialize())
	vtube_data["ArtMeshDetails"]["ArtMeshesExcludedFromPinning"] = get_meshes().filter(
		func (mesh):
			return mesh.get_meta("pinnable", false) == false
	).map(
		func (mesh):
			return mesh.name
	)
	vtube_data["ArtMeshDetails"]["ArtMeshMultiplyAndScreenColors"] = get_meshes().filter(
		func (mesh):
			return mesh.get_instance_shader_parameter("color_override") == true
	).map(
		func (mesh):
			return {
				"ID": mesh.name,
				"Value": "%s|%s" % [
					Math.v4rgba(mesh.get_instance_shader_parameter("color_multiply")).to_html(true),
					Math.v4rgba(mesh.get_instance_shader_parameter("color_screen")).to_html(true)
				]
			}
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
		var exclude = mesh.name in pin_settings
		mesh.set_meta("pinnable", not exclude)
		
		if mesh.name in tint:
			var colors = tint[mesh.name]
			mesh.set_instance_shader_parameter("color_override", true)
			mesh.set_instance_shader_parameter("color_multiply", colors.multiply)
			mesh.set_instance_shader_parameter("color_screen", colors.screen)

## load open-vt specific settings
func _load_settings():
	var model_preferences = Files.read_json(modelmeta.openvt_parameters)
	self.scale = Vector2.ONE * model_preferences.get("transform", {}).get(
		"scale", 
		clampf(get_viewport_rect().size.y / size.y, 0.001, 2.0)
	)
	self.rotation_degrees = model_preferences.get("transform", {}).get("rotation", 0)
	self.texture_filter = TEXTURE_FILTER_NEAREST_WITH_MIPMAPS_ANISOTROPIC if model_preferences.get("quality", {}).get("filter", "linear") == "nearest" else TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	self.smoothing = model_preferences.get("quality", {}).get("smoothing", false)
		
	self.position = Serializers.Vec2Serializer.from_json(
		model_preferences.get("transform", {}).get("position", {}),
		get_viewport_rect().get_center()
	)

func save_settings(_settings: Dictionary):
	if not is_initialized():
		return
	
	_save_to_vts()
	
	var model_data  = {
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
	}
	
	for o in get_tree().get_nodes_in_group("persist:model"):
		o.save_settings(model_data)
	Files.write_json(modelmeta.openvt_parameters, model_data)
