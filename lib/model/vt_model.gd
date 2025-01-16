# System for loading models from VTubeStudio's format
# and spawning them into the scene to be managed
extends Node2D

const utils = preload("res://lib/utils.gd")
const ParameterSetting = preload("res://lib/tracking/parameter_setting.gd")
const Draggable = preload("res://lib/draggable.gd")
const ModelMeta = preload("./metadata.gd")

@onready var drag: Draggable = %Drag
@onready var live2d_model = %GDCubismUserModel
var model: ModelMeta

var parameters_l2d: Array
var model_parameters: Dictionary
var filter: CanvasItem.TextureFilter :
	set(v):
		filter = v
		live2d_model.texture_filter = filter
		if filter == CanvasItem.TextureFilter.TEXTURE_FILTER_NEAREST:
			live2d_model.shader_add = preload("res://addons/gd_cubism/res/nearest_shader/2d_cubism_norm_add.gdshader")
			live2d_model.shader_mix = preload("res://addons/gd_cubism/res/nearest_shader/2d_cubism_norm_mix.gdshader")
			live2d_model.shader_mul = preload("res://addons/gd_cubism/res/nearest_shader/2d_cubism_norm_mul.gdshader")
		else:
			live2d_model.shader_add = preload("res://addons/gd_cubism/res/shader/2d_cubism_norm_add.gdshader")
			live2d_model.shader_mix = preload("res://addons/gd_cubism/res/shader/2d_cubism_norm_mix.gdshader")
			live2d_model.shader_mul = preload("res://addons/gd_cubism/res/shader/2d_cubism_norm_mul.gdshader")
			
var parameters: Array :
	get():
		return %Parameters.get_children()

func is_bound(parameter: GDCubismParameter) -> bool:
	return has_node(parameter.id)

func _ready():
	var placeholder = live2d_model
	
	live2d_model = GDCubismUserModel.new()
	live2d_model.assets = model.model
	placeholder.replace_by(live2d_model)
	placeholder.queue_free()
	
	var canvas_info = live2d_model.get_canvas_info()
	# drag.size = live2d_model.get_canvas_info().size_in_pixels
	%Model.position = -live2d_model.get_canvas_info().origin_in_pixels
	
	var vtube_data = JSON.parse_string(FileAccess.get_file_as_string(model.studio_parameters))
	var model_data = JSON.parse_string(FileAccess.get_file_as_string(model.model))
	var display_data = JSON.parse_string(FileAccess.get_file_as_string(model.model_parameters))
	
	var output_parameters = display_data["Parameters"]
	parameters_l2d = live2d_model.get_parameters()
	for i in parameters_l2d:
		model_parameters[i.id] = i
		
	var tracking = get_tree().get_first_node_in_group("system:tracking")

	for parameter_data in vtube_data["ParameterSettings"]:
		var p = preload("res://lib/tracking/parameter_setting.gd").new()
		var ok = p.deserialize(parameter_data)
		if ok:
			p.model_parameter = model_parameters[p.output_parameter]
			%Parameters.add_child(p)
		if tracking != null:
			tracking.parameters_updated.connect(p.update)
			
	var transform = vtube_data.get("SavedModelPosition", {})
	position = utils.vts_to_world(Vector2(transform.get("Position", {}).get("x", 0.0), transform.get("Position", {}).get("y", 0.0)))
	scale = Vector2(transform.get("Scale", {}).get("x", 0.0), transform.get("Scale", {}).get("y", 0.0))
	rotation = transform.get("Rotation", {}).get("z", 0.0)
	
	await get_tree().process_frame
	
func add_parameter():
	var p = preload("res://lib/tracking/parameter_setting.gd").new()
	%Parameters.add_child(p)
