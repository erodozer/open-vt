extends Node2D

const VtModel = preload("res://lib/model/vt_model.gd")

@onready var model: VtModel = get_parent()

func _process(_delta: float) -> void:
	if not visible:
		return
		
	queue_redraw()
	
func _draw() -> void:
	for m in model.get_meshes():
		if not model.get("modifiers/meshes/%s/pinnable" % [m.name]):
			continue
			
		if not m.visible:
			continue
		
		draw_circle(m.get_meta("centroid", Vector2.ZERO), 2, Color.BLUE, true, -1.0, true)
