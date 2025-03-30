extends SubViewportContainer

const MAX_QUALITY = Vector2(4096, 4096)

@onready var viewport: SubViewport = $SubViewport
@onready var parent: Control = get_parent()
@export var model: GDCubismUserModel

func _ready():
	viewport.add_child(model)

func _process(_delta: float) -> void:
	var _scale = parent.get_scale()
	var s = _scale.clamp(Vector2(0.01, 0.01), Vector2.ONE)
	var canvas_size = model.get_canvas_info().size_in_pixels
	viewport.canvas_transform = Transform2D(0.0, s, 0, Vector2.ZERO)
	var scaled = (canvas_size * s).clamp(Vector2(2,2), canvas_size.min(MAX_QUALITY))
	var ratio = scaled / canvas_size
	viewport.size = scaled
	scale = Vector2.ONE / s
	pivot_offset = Vector2.ZERO
	# render.size = viewport.size
	#if _scale < Vector2.ONE:
	#	self.scale = Vector2.ONE / _scale
	#else:
	#	self.scale = Vector2.ONE
	
