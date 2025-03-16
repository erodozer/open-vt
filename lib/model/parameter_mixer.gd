extends Node

const Provider = preload("./parameter_value_provider.gd")

var parameters : Dictionary :
	get():
		var model: GDCubismUserModel = get_parent().live2d_model
		return model.parameters
	
func _process(delta: float) -> void:
	var model: GDCubismUserModel = get_parent().live2d_model
	if model == null:
		return
	
	var values = {}
	for i in model.parameters:
		values[i] = model.parameters[i]["default"]
	
	var modified = {}
	for i in get_children():
		var provider: Provider = i
		provider.apply(modified)
	
	values.merge(modified, true);
	
	for p_name in values:
		model.set(p_name, float(values[p_name]))
