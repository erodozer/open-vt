# System for loading models from VTubeStudio's format
# and spawning them into the scene to be managed
extends Node

const ParameterSetting = preload("res://lib/tracking/parameter_setting.gd")
const ModelMeta = preload("./metadata.gd")

@onready var live2d_model: GDCubismUserModel = $GDCubismUserModel
@onready var renderer: TextureRect = $Model
var model: ModelMeta

var parameters_l2d: Array
var model_parameters: Dictionary
var filter: CanvasItem.TextureFilter :
	set(v):
		filter = v
		renderer.texture_filter = filter
var parameters: Array :
	get():
		return %Parameters.get_children()

func is_bound(parameter: GDCubismParameter) -> bool:
	return has_node(parameter.id)

func _ready():
	live2d_model.assets = model.model
	live2d_model.size = live2d_model.get_canvas_info().size_in_pixels
	
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

func add_parameter():
	var p = preload("res://lib/tracking/parameter_setting.gd").new()
	%Parameters.add_child(p)
