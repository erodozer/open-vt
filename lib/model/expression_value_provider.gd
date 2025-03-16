extends "./parameter_value_provider.gd"

@export var expression_controller: GDCubismExpressionController

func apply(values: Dictionary):
	if weight == 0.0:
		return
	
	var modified = values.duplicate()
	expression_controller.apply(
		modified,
		self.parameters,
	)
	var ary_parameters = modified.keys()
	for p_name in ary_parameters:
		var param: Dictionary = parameters[p_name]
		var default_value: float = param["default"]

		var from_v = values.get(p_name, default_value)
		var to_v = modified[p_name]
		values[p_name] = lerp(
			from_v,
			to_v,
			weight
		)
