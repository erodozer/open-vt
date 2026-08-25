extends BaseButton

@export var link: CanvasItem
@export var invert: bool = false

func _ready() -> void:
	toggled.connect(toggle_visibility)
	toggle_visibility()
	
func toggle_visibility(vis = button_pressed):
	link.visible = vis if not invert else not vis
