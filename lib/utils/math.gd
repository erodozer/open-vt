extends Object

static func v32xy(v: Vector3) -> Vector2:
	return Vector2(
		v.x, v.y
	)

static func v32xz(v: Vector3) -> Vector2:
	return Vector2(
		v.x, v.z
	)

static func v32yz(v: Vector3) -> Vector2:
	return Vector2(
		v.y, v.z
	)
	
static func v23xy(v: Vector2) -> Vector3:
	return Vector3(
		v.x, v.y, 0
	)

static func v23yz(v: Vector2) -> Vector3:
	return Vector3(
		0, v.x, v.y
	)
	
static func v23xz(v: Vector2) -> Vector3:
	return Vector3(
		v.x, 0, v.y
	)
	
static func v4rgba(v) -> Color:
	if v is Color:
		return v
	assert(v is Vector4)
	return Color(
		v.x, v.y, v.z, v.w
	)
	
## Naive centroid calculation by looking for the average position of all vertices.[br]
## If you want an actual weighted centroid that considers the surface area and shape of a convex hull
## this is not the implementation you want.
static func centroid(points: Array) -> Vector3:
	var s: Vector3 = Vector3.ZERO
	for p in points:
		if p is Vector2:
			p = v23xy(p)
		s += p
	return s / len(points)

# unit scale the VTS appears to use
const UNITY_PPU = 100
const UNITY_VIEWPORT = Transform2D(0, Vector2(1920, 1080), 0, Vector2(-960, -540))

## Convert a vector in unity coordinates to Godot's canvas coordinate system
## [br]
## note: Unity canvas origin is centered to the window instead of top left
static func unity_to_canvas(vp: Viewport, v: Vector2) -> Vector2:
	return UNITY_VIEWPORT.basis_xform(v)
