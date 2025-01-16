extends Control

@onready var anchor: Node2D = get_parent()

signal transform_updated(position: Vector2, scale: Vector2, rotation: float)

func _gui_input(event: InputEvent) -> void:
	var dirty = false
	if event is InputEventMouseButton:
		if Input.is_key_pressed(KEY_CTRL):
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				anchor.rotation_degrees += 1
				dirty = true
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				anchor.rotation_degrees -= 1
				dirty = true
			elif event.button_index == MOUSE_BUTTON_MIDDLE:
				anchor.rotation_degrees = 0
				dirty = true
			anchor.rotation_degrees = wrapi(anchor.rotation_degrees, 0, 359)
		else:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				anchor.scale += Vector2(0.01, 0.01)
				dirty = true
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				anchor.scale -= Vector2(0.01, 0.01)
				dirty = true
			anchor.scale = clamp(anchor.scale, Vector2(0.1, 0.1), Vector2(5, 5))
		
	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			anchor.position += event.screen_relative
			dirty = true
	
	if dirty:
		transform_updated.emit(anchor.position, anchor.scale, anchor.rotation)
