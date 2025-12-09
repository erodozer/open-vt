extends "res://ui/draggable.gd"

@export var display_name: String
@export var sort_order: int = 0 :
	set(z):
		sort_order = z
		
@export var mirror : bool = false :
	set(v):
		mirror = v
		render.scale = Vector2(-1.0 if v else 1.0, 1.0)

var render: Node2D

signal request_delete

func _unhandled_input(event: InputEvent) -> void:
	super._unhandled_input(event)
	
	if event.is_action_pressed("delete_item") and dragging:
		request_delete.emit()
	
