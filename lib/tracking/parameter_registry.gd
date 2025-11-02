extends Node

var _registry = {
	"unset": {
		"id": "unset",
		"range": Vector2.ZERO,
		"default_value": 0.0
	}
}
var _dirty = false

signal parameter_list_changed

func parameters() -> Array:
	return _registry.values()

func _get(param: StringName) -> Variant:
	if param not in _registry:
		return null
	
	var meta: Dictionary = _registry.get(param, {})
	return meta.duplicate()

func _emit_list_update():
	if _dirty:
		parameter_list_changed.emit()
		_dirty = false

func add_parameter(parameter_name: StringName, range: Vector2 = Vector2(0, 1), default: float = 0.0):
	_registry[parameter_name] = {
		"id": parameter_name,
		"range": range,
		"default_value": default
	}
	_dirty = true
	# debounce changes
	_emit_list_update.call_deferred()

func get_default(parameter_name: StringName):
	return _registry.get(parameter_name, {}).get("default_value", 0)

func clamp_to_range(value: float, param: StringName) -> float:
	var range: Vector2 = _registry.get(param, {}).get("range", Vector2.ZERO)
	return clampf(
		value,
		range.x, range.y
	)

func ilerp_input(value: float, param: StringName) -> float:
	var range: Vector2 = _registry.get(param, {}).get("range", Vector2.ZERO)
	return inverse_lerp(
		range.x, range.y,
		value
	)
	
func signed_ilerp_input(value: float, param: StringName) -> float:
	var range: Vector2 = _registry.get(param, {}).get("range", Vector2.ZERO)
	return inverse_lerp(
		0, range.y,
		value
	)
