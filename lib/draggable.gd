extends Control

@onready var anchor: Node2D = get_parent()

signal transform_updated(position: Vector2, scale: Vector2, rotation: float)
signal drag_released

var dragging = false

func _handle_mouse_button_down(event: InputEventMouseButton):
	var dirty = false
	
	# check for simultaneous inputs to perform different actions
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
		
	if event.button_index == MOUSE_BUTTON_LEFT:
		dragging = true
	
	return dirty

func _handle_mouse_motion(event: InputEventMouseMotion) -> bool:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		anchor.position += event.screen_relative
		return true
	return false

# can't use gui_input because if the mouse input is within the bounds of the element,
# it won't pass through to other controls, inhibiting clicking objects
# this behavior conflicts with the ability to handle mouse input relative to sampled pixels
# so that we can ignore clicking on transparent parts
func _unhandled_input(event: InputEvent) -> void:
	var dirty = false
	if event is InputEventMouseButton:
		if event.pressed:
			# mouse event must be within the bounds of the control
			var p_xy = self.get_local_mouse_position() / self.scale
			if not (p_xy.x >= 0 and p_xy.x < self.size.x and p_xy.y >= 0 and p_xy.y < self.size.y):
				return
			# sample for alpha if control has texture
			if "texture" in self:
				var px = self.texture.get_image().get_pixelv(p_xy)
				var opaque = px.a > 0.0
				if not opaque:
					return
			dirty = dirty || _handle_mouse_button_down(event)
			accept_event()
		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT and dragging:
			dragging = false
			drag_released.emit()
			accept_event()
		else:
			return
		
	if dragging and event is InputEventMouseMotion:
		dirty = dirty || _handle_mouse_motion(event)
		accept_event()
	
	if dirty:
		transform_updated.emit(anchor.position, anchor.scale, anchor.rotation)
