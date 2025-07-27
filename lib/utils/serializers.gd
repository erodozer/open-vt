extends Object

class JsonSerializer:
	func to_json(v) -> Dictionary:
		return {}
	func from_json(d, fallback = null):
		return fallback

class Vec2SerializerImpl extends JsonSerializer:
	func to_json(v: Vector2) -> Dictionary:
		return {
			"x": v.x,
			"y": v.y,
		}
	func from_json(v: Dictionary, fallback: Vector2 = Vector2.ZERO) -> Vector2:
		return Vector2(
			v.get("x", fallback.x),
			v.get("y", fallback.y)
		)

static var Vec2Serializer: JsonSerializer = Vec2SerializerImpl.new()

class RangeSerializerImpl extends JsonSerializer:
	func to_json(v: Vector2) -> Dictionary:
		return {
			"min": v.x,
			"max": v.y
		}
	func from_json(v: Dictionary, fallback: Vector2 = Vector2(0, 1)) -> Vector2:
		return Vector2(
			v.get("min", fallback.x),
			v.get("max", fallback.y)
		)

static var RangeSerializer: JsonSerializer = RangeSerializerImpl.new()
