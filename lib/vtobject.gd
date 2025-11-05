extends "res://ui/draggable.gd"

@export var display_name: String
@export var sort_order: int = 0 :
	set(z):
		sort_order = z
		z_index = sort_order * 1000
		
@export var mirror : bool = false :
	set(v):
		mirror = v
		render.scale = Vector2(-1.0 if v else 1.0, 1.0)

var render: Node2D
