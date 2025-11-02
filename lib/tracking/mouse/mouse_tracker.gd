extends "res://lib/tracking/tracker.gd"

func _ready():
	Registry.add_parameter("MousePositionX", Vector2(-1.0, 1.0), 0.0)
	Registry.add_parameter("MousePositionY", Vector2(-1.0, 1.0), 0.0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var mouse = DisplayServer.mouse_get_position()
	var size = DisplayServer.screen_get_size()
	var center = size / 2
	
	update({
		"MousePositionX": inverse_lerp(center.x, size.x, mouse.x),
		"MousePositionY": inverse_lerp(center.y, size.y, mouse.y)
	})
