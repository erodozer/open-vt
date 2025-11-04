extends Node2D

enum SampleMode {
	BOUNDS,
	ALPHA
}

signal transform_updated(position: Vector2, scale: Vector2, rotation: float)
signal drag_pressed
signal drag_released

@export var locked = false
@export var sample_mode = SampleMode.BOUNDS
@export var centered = true
@export var debug = false
var dragging = false

var size: Vector2 = Vector2.ONE :
	set(v):
		size = v
		var offset = (-size / 2) if centered else Vector2.ZERO
		RenderingServer.canvas_item_set_custom_rect(
			get_canvas_item(), true, 
			Rect2(position + offset, v)
		)
		queue_redraw()
		
var rect: Rect2 :
	get():
		var offset = (-size / 2) if centered else Vector2.ZERO
		return Rect2(offset, size)

func _draw() -> void:
	if debug:
		draw_rect(
			rect,
			Color.GREEN, false, -3.0, true
		)

func _handle_mouse_button_down(event: InputEventMouseButton):
	var dirty = false
	
	# check for simultaneous inputs to perform different actions
	if dragging:
		if Input.is_key_pressed(KEY_CTRL):
			var rot = 0
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				rot += 1
				dirty = true
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				rot -= 1
				dirty = true
			elif event.button_index == MOUSE_BUTTON_MIDDLE:
				rot = 0
				dirty = true
			if dirty:
				rotation_degrees = wrapi(int(ceil(rotation_degrees + rot)), 0, 359)
		else:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				scale += Vector2(0.01, 0.01)
				dirty = true
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				scale -= Vector2(0.01, 0.01)
				dirty = true
			scale = clamp(scale, Vector2(0.01, 0.01), Vector2(5.0, 5.0))
		
	if event.button_index == MOUSE_BUTTON_LEFT:
		dragging = true
		drag_pressed.emit()
	
	return dirty

func _handle_mouse_motion(event: InputEventMouseMotion) -> bool:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		global_position += event.relative
		return true
	return false

# can't use gui_input because if the mouse input is within the bounds of the element,
# it won't pass through to other controls, inhibiting clicking objects
# this behavior conflicts with the ability to handle mouse input relative to sampled pixels
# so that we can ignore clicking on transparent parts
func _unhandled_input(event: InputEvent) -> void:
	# prevent transformations
	if locked:
		return
	
	var dirty = false
	if event is InputEventMouseButton:
		if event.pressed:
			# mouse event must be within the bounds of the control
			var p_xy = self.get_local_mouse_position()
			if not rect.has_point(p_xy):
				return
			# sample for alpha if control has texture
			if "texture" in self and sample_mode == SampleMode.ALPHA:
				var px = self.texture.get_image().get_pixelv(p_xy)
				var opaque = px.a > 0.0
				if not opaque:
					return
			dirty = dirty || _handle_mouse_button_down(event)
			get_viewport().set_input_as_handled()
		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT and dragging:
			dragging = false
			drag_released.emit()
			get_viewport().set_input_as_handled()
		else:
			return
		
	if dragging and event is InputEventMouseMotion:
		dirty = dirty || _handle_mouse_motion(event)
		get_viewport().set_input_as_handled()
	
	if dirty:
		transform_updated.emit(position, scale, rotation)
