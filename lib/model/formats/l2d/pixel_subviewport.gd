extends SubViewportContainer

const SUPER_SAMPLE = 2.0
const MAX_QUALITY = Vector2(4096, 4096)

@onready var viewport: SubViewport = $SubViewport
@onready var parent: CanvasItem = get_parent()
@export var model: GDCubismUserModel :
	set(m):
		if m == null:
			viewport.size = Vector2i.ONE
			return
			
		model = m
		model.scale = Vector2.ONE * SUPER_SAMPLE
		# model.origin *= SUPER_SAMPLE
		model.reparent(viewport, false)
		
		var canvas_size: Vector2 = Vector2(model.get_size())
		var scaled = canvas_size
		var ratio = Vector2.ONE
		if canvas_size.x > MAX_QUALITY.x || canvas_size.y > MAX_QUALITY.y:
			ratio = Vector2.ONE * min(MAX_QUALITY.x / canvas_size.x, MAX_QUALITY.y / canvas_size.y)
			scaled = canvas_size * ratio
		viewport.size = scaled
		viewport.canvas_transform = Transform2D(0.0, ratio, 0, Vector2.ZERO)
		scale = Vector2.ONE / ratio
	
