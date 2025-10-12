extends Object

static var _registry = {
	"unset": {
		"id": "unset",
		"range": Vector2.ZERO,
		"default_value": 0.0
	}
}

static func add_parameter(parameter_name: StringName, range: Vector2, default: float):
	_registry[parameter_name] = {
		"id": parameter_name,
		"range": range,
		"default_value": default
	}

static func clamp_to_range(value: float, param: StringName) -> float:
	var range: Vector2 = _registry.get(param, {}).get("range", Vector2.ZERO)
	return clamp(
		value,
		range.x, range.y
	)

static func ilerp_input(value: float, param: StringName) -> float:
	var range: Vector2 = _registry.get(param, {}).get("range", Vector2.ZERO)
	return inverse_lerp(
		range.x, range.y,
		value
	)
	
static func signed_ilerp_input(value: float, param: StringName) -> float:
	var range: Vector2 = _registry.get(param, {}).get("range", Vector2.ZERO)
	return inverse_lerp(
		0, range.y,
		value
	)
