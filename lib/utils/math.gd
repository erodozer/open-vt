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
	
## Naive centroid calculation by looking for the average position of all vertices
## If you want an actual weighted centroid that considers the surface area and shape of a convex hull
## this is not the implementation you want.
static func centroid(points: Array) -> Vector3:
	var s: Vector3 = Vector3.ZERO
	for p in points:
		if p is Vector2:
			p = v23xy(p)
		s += p
	return s / len(points)
