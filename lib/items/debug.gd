extends Node2D

const utils = preload("res://lib/utils.gd")
const VtModel = preload("res://lib/model/vt_model.gd")

func _process(delta: float) -> void:
	if not visible:
		return
		
	queue_redraw()
	
func _draw() -> void:
	var centroid = get_parent().size / 2
	draw_circle(centroid, 2, Color.RED, true, -1.0, true)
