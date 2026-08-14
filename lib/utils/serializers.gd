extends Object

@abstract class JsonSerializer:
	@abstract func to_json(v) -> Dictionary
	@abstract func from_json(d, fallback = null)

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

class ObjSerializerImpl extends JsonSerializer:
	func to_json(v: Object) -> Dictionary:
		var out = {}
		var props = v.get_property_list()
		for p in props:
			if not (p.usage & PropertyUsageFlags.PROPERTY_USAGE_STORAGE):
				continue
			if p.usage & PropertyUsageFlags.PROPERTY_USAGE_INTERNAL:
				continue
			var value = v.get(p.name)
			if p.type == Variant.Type.TYPE_COLOR:
				value = (value as Color).to_html(true)
			if p.type == Variant.Type.TYPE_VECTOR2:
				value = Vec2SerializerImpl.new().to_json(value)
			out[p.name] = value
		return out
		
	func from_json(v: Dictionary, assign = null):
		var props = assign.get_property_list()
		for p in props:
			if not (p.usage & PropertyUsageFlags.PROPERTY_USAGE_STORAGE):
				continue
			if p.usage & PropertyUsageFlags.PROPERTY_USAGE_INTERNAL:
				continue
			var existing = assign.get(p.name)
			var value = v.get(p.name)
			if p.type == Variant.Type.TYPE_COLOR:
				if existing is Dictionary:
					value = Color(
						existing.r, existing.g, existing.b, existing.get("a", 1.0)
					)
				elif existing is String:
					value = Color.from_string(value, existing as Color)
				else:
					value = Color.WHITE
			if p.type == Variant.Type.TYPE_VECTOR2:
				value = Vec2SerializerImpl.new().from_json(value, existing as Vector2)
			if value == null:
				value = existing
			assign.set(p.name, value)
		return assign
	
static var ObjSerializer: JsonSerializer = ObjSerializerImpl.new()
