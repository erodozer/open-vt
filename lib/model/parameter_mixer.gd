extends Node

const Provider = preload("./parameter_value_provider.gd")

var parameters : Dictionary :
	get():
		var model: GDCubismUserModel = get_parent().live2d_model
		return model.parameters
	
func _process(_delta: float) -> void:
	if get_parent() == null or not get_parent().is_initialized():
		return
		
	var model: GDCubismUserModel = get_parent().live2d_model
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
