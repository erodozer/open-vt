extends Node2D

const VtModel = preload("res://lib/model/vt_model.gd")

@export var model: VtModel

func _process(_delta: float) -> void:
	if not visible:
		return
		
	queue_redraw()
	
func _draw() -> void:
	for m in model.get_meshes():
		if not model.format_strategy.get_modifiers(m).get("pinnable", {}).get("enabled", true):
			continue
			
		if not m.visible:
			continue
		
		draw_circle(m.get_meta("centroid"), 2, Color.BLUE, true, -1.0, true)
