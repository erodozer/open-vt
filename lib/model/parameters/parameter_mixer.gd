extends Node

const Provider = preload("./parameter_value_provider.gd")

func parameters() -> Dictionary[String, Dictionary] :
	return get_parent().parameters
	
func _process(_delta: float) -> void:
	if get_parent() == null or not get_parent().is_initialized():
		return
		
	var values: Dictionary[String, float] = {}
	var params = parameters()
	for i in params:
		values[i] = params[i]["default"]
	
	var modified = {}
	for i in get_children():
		var provider: Provider = i
		provider.apply(modified)
	
	values.merge(modified, true);
	
	get_parent().format_strategy.apply_parameters(values)
