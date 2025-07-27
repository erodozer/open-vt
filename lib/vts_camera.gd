extends Camera2D

const VTS_VIEWPORT = Vector2(1280, 720)
const VTS_ASPECT = VTS_VIEWPORT.y / VTS_VIEWPORT.x
const VTS_WORLD = Vector2(100, 100) # vts appears to have a world that's 100 wide in each direction

static func world_to_vts(_v: Vector2):
	pass

static func vts_to_world(v: Vector2):
	#var xy = v / VTS_WORLD - Vector2(0.5, 0.5)
	
	return Vector2(
		lerp(0.0, VTS_VIEWPORT.x, inverse_lerp(-VTS_WORLD.x, VTS_WORLD.x, v.x)),
		# unity's y coord are flipped
		lerp(0.0, VTS_VIEWPORT.y, inverse_lerp(-VTS_WORLD.y, VTS_WORLD.y, -v.y))
	)

func _ready() -> void:
	get_viewport().size_changed.connect(_update_zoom)
	_update_zoom()

func _update_zoom():
	var viewport = get_viewport_rect()
	var scale_factor = viewport.size.y / VTS_VIEWPORT.y
	# zoom = Vector2.ONE * scale_factor
