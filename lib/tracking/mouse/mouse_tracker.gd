extends "res://lib/tracking/tracker.gd"

func _ready():
	# Screen Position
	Registry.add_parameter("MousePositionX", Vector2(-1.0, 1.0), 0.0, "KBM")
	Registry.add_parameter("MousePositionY", Vector2(-1.0, 1.0), 0.0, "KBM")
	
	# Button State
	Registry.add_parameter("MousePressedLeft", Vector2.ONE, 0.0, "KBM")
	Registry.add_parameter("MousePressedRight", Vector2.ONE, 0.0, "KBM")
	Registry.add_parameter("MousePressedMiddle", Vector2.ONE, 0.0, "KBM")
	
	# Tablet State
	Registry.add_parameter("PenPressure", Vector2.ONE, 0.0, "KBM")
	#Registry.add_parameter("PenTiltX", Vector2(-1.0, 1.0), 0.0, "KBM")
	#Registry.add_parameter("PenTiltY", Vector2(-1.0, 1.0), 0.0, "KBM")
	
	Input.use_accumulated_input = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		update({
			"PenPressure": event.pressure,
		#	"PenTiltX": event.tilt.x,
		#	"PenTiltY": event.tilt.y,
		})

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var mouse = DisplayServer.mouse_get_position()
	var size = DisplayServer.screen_get_size()
	var center = size / 2
	
	update({
		"MousePositionX": inverse_lerp(center.x, size.x, mouse.x),
		"MousePositionY": inverse_lerp(center.y, size.y, mouse.y),
		"MousePressedLeft": Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT),
		"MousePressedRight": Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT),
		"MousePressedMiddle": Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE),
	})
