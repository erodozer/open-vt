extends "res://lib/tracking/tracker.gd"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var mouse = DisplayServer.mouse_get_position()
	var size = DisplayServer.screen_get_size()
	var center = size / 2
	
	parameters = {
		Inputs.MOUSE_POSITION_X: inverse_lerp(center.x, size.x, mouse.x),
		Inputs.MOUSE_POSITION_Y: inverse_lerp(center.y, size.y, mouse.y)
	}
