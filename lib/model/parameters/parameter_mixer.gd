extends Node

const Provider = preload("./parameter_value_provider.gd")

var parameters : Dictionary :
	get():
		return get_parent().parameters
	
func _process(delta: float) -> void:
	if get_parent() == null or not get_parent().is_initialized():
		return
		
	var values = {}
	for i in parameters:
		values[i] = parameters[i]["default"]
	
	var modified = {}
	for i in get_children():
		var provider: Provider = i
		provider.apply(modified, delta)
	
	values.merge(modified, true);
	
	get_parent().parameters = values
