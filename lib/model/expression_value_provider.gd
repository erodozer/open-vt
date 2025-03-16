extends "./parameter_value_provider.gd"

var expression_library: Dictionary[StringName, GDCubismExpression]
var weights: Dictionary[StringName, float]
var fade: Dictionary = {}
var order: Array[StringName] = []

func queue_expression(expression_name: StringName, fade: float, reverse: bool):
	var start = Time.get_unix_time_from_system()
	var end = start + fade

	var fade_time = {
		"start": start,
		"end": end,
		"reverse": reverse
	}
	fade_time["start"] = start;
	fade_time["end"] = end;
	fade_time["reverse"] = reverse;
	self.fade[expression_name] = fade_time

func clear(fade: float):
	for i in self.order:
		queue_expression(i, fade, true)

func is_activated(expression_name: StringName):
	if expression_name.is_empty():
		return self.order.is_empty()
	return self.order.find(expression_name) > -1

func set_expression(expression_name: StringName, fade: float):
	var expression: GDCubismExpression = expression_library.get(expression_name)
	if expression == null:
		return
	
	if is_activated(expression_name):
		return
	
	self.order.clear()
	self.fade.clear()
	
	activate_expression(expression_name, fade)

func deactivate_expression(expression_name: String, fade: float):
	var expression: GDCubismExpression = expression_library.get(expression_name)
	if expression == null:
		return
	if !is_activated(expression_name):
		return
	
	queue_expression(expression_name, fade, true)

func activate_expression(expression_name: String, fade: float):
	var expression: GDCubismExpression = expression_library.get(expression_name)
	if expression == null:
		return
	if is_activated(expression_name):
		return
	
	queue_expression(expression_name, fade, false)
	order.append(expression_name)

func _get(p_name: StringName) -> Variant:
	if expression_library.has(p_name):
		return weights.get(p_name, 0.0)
	return null
	
func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []
	properties.append(
		{
			"name": "Expressions",
			"hint": PROPERTY_HINT_NONE,
			"usage": PROPERTY_USAGE_GROUP
		}
	)
	
	for e in expression_library:
		properties.append(
			{
				"name": e,
				"type": TYPE_FLOAT,
				"hint": PROPERTY_HINT_RANGE,
				"hint_string": "0.0,1.0",
				"usage": PROPERTY_USAGE_DEFAULT
			}
		)
	
	properties.append(super._get_property_list())
	return properties

func update(values: Dictionary):
	var now: float = Time.get_unix_time_from_system()
	
	#apply expressions to parameters, with the parameter value being the set by the most recently activated expression
	var modified = {}
	var order = order.duplicate()
	
	var n = 0
	for i in range(len(order)):
		var exp_name: StringName = order[i]
		var exp: GDCubismExpression = expression_library[exp_name]
		
		var fade: Dictionary = self.fade[exp_name]
		var progress = clamp(inverse_lerp(fade["start"], fade["end"], now), 0.0, 1.0)
		if fade["reverse"] == true:
			progress = 1.0 - progress
			
		weights[exp_name] = progress

		var ary_parameters = exp.get_parameters()
		for e in ary_parameters:
			var p_name: String = e["Id"]
			var blend: String = e["Blend"]
			var amount: float = e["Value"]
			var param: Dictionary = parameters[p_name];
			
			var v: float = values.get(p_name, param["default"])
			var to_v: float = v;

			match blend:
				"Add":
					to_v = v + amount
				"Multiply":
					to_v = v * (1.0 + (amount - 1.0))
				"Overwrite":
					to_v = amount;
				_:
					continue

			var out: float = lerp(
				v,
				to_v,
				progress
			)

			# prevent emotion controller from having a permanent affect on the parameter
			modified[p_name] = out

		# dequeue after reversal complete
		if fade["reverse"] && progress <= 0.0:
			self.order.pop_at(n)
		else:
			n += 1
	
	values.merge(modified, true)

func apply(values: Dictionary):
	if weight == 0.0:
		return
	
	var modified = values.duplicate()
	update(modified)
	
	var ary_parameters = modified.keys()
	for p_name in ary_parameters:
		var param: Dictionary = self.parameters[String(p_name)]
		var default_value: float = param["default"]

		var from_v = values.get(p_name, default_value)
		var to_v = modified[p_name]
		self.values[p_name] = lerp(
			from_v,
			to_v,
			weight
		)
	
	values.merge(self.values, true)
	
