extends Node2D

const utils = preload("res://lib/utils.gd")
const VtModel = preload("res://lib/model/vt_model.gd")

@export var model: VtModel

func _process(delta: float) -> void:
	if not visible:
		return
		
	queue_redraw()
	
func _draw() -> void:
	for m in model.get_meshes():
		if not model.pinnable.get(m.name, false):
			continue
			
		if not m.visible:
			continue
		
		draw_circle(m.get_meta("centroid"), 2, Color.BLUE, true, -1.0, true)
