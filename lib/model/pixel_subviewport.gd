extends SubViewportContainer

@onready var viewport: SubViewport = $SubViewport
@onready var parent: Control = get_parent()
@export var model: GDCubismUserModel

func _ready():
	viewport.add_child(model)

func _process(_delta: float) -> void:
	var scale = parent.scale
	var s = clamp(scale, Vector2(0.01, 0.01), Vector2.ONE)
	viewport.canvas_transform = Transform2D(0.0, s, 0, Vector2.ZERO)
	viewport.size = clamp(model.get_canvas_info().size_in_pixels * s, Vector2(2,2), model.get_canvas_info().size_in_pixels)
	# render.size = viewport.size
	if scale < Vector2.ONE:
		self.scale = Vector2.ONE / scale
	else:
		self.scale = Vector2.ONE
	
