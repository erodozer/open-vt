extends Node

@export_range(0.0, 1.0, 0.001) var weight: float = 1.0
var values = {}

var parameters: Dictionary :
	get():
		if get_parent() != null:
			return get_parent().parameters
		return {}
	
func reset():
	values.clear()
	
func _set(property: StringName, value: Variant) -> bool:
	if parameters != null and parameters.has(property):
		values[property] = clampf(
			float(value),
			parameters[property].min,
			parameters[property].max
		)
		return true
	return false
	
func _get(property: StringName) -> Variant:
	if values.has(property):
		return values[property]
	return null
	
func _validate_property(property: Dictionary) -> void:
	if property["name"] == "parameters":
		property["usage"] = PROPERTY_USAGE_NO_EDITOR
	
func _get_property_list():
	var properties = []
	properties.append(
		{
			"name": "Parameters",
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_NONE,
		}
	)
	
	for p in parameters:
		properties.append(
			{
				"name": p,
				"type": TYPE_FLOAT,
				"hint": PROPERTY_HINT_RANGE,
				"hint_string": "%f,%f" % [parameters[p]["min"], parameters[p]["max"]],
			}
		)
		
	return properties

func update(inputs: Dictionary, delta: float):
	pass

func apply(inputs: Dictionary, delta: float):
	if weight == 0.0:
		return
	
	var modified = inputs.duplicate()
	update(modified, delta)
	
	var ary_parameters = self.values.keys()
	for p_name in ary_parameters:
		if not (p_name in parameters):
			continue
			
		var param: Dictionary = parameters[p_name]
		var default_value: float = param["default"]

		var from_v = modified.get(p_name, default_value)
		var to_v = self.values[p_name]
		inputs[p_name] = lerp(
			from_v,
			to_v,
			weight
		)
