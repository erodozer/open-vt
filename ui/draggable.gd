extends Node2D

const Math = preload("res://lib/utils/math.gd")

enum SampleMode {
	BOUNDS,
	ALPHA
}

signal transform_updated(position: Vector2, scale: Vector2, rotation: float, offset: Vector2, yrp: Vector3)
signal drag_pressed
signal drag_released

@export var locked = false
@export var sample_mode = SampleMode.BOUNDS
@export var centered = false :
	set(v):
		centered = v
		_update_rect()
		
@export var debug = false
var dragging = false

var size: Vector2 = Vector2.ONE :
	set(v):
		size = v
		_update_rect()
		
var rect: Rect2 :
	get():
		var offset = (-size / 2) if centered else Vector2.ZERO
		return Rect2(offset, size)
		
var center: Vector2 :
	get():
		return rect.get_center()

# extra transformations, useful for 3D draggables
var free_rotation: Vector3
var free_offset: Vector2 = Vector2.ZERO

func _draw() -> void:
	if debug:
		draw_rect(
			rect,
			Color.GREEN, false, 8.0, false
		)

func _update_rect():
	var offset = (-size / 2) if centered else Vector2.ZERO
	RenderingServer.canvas_item_set_custom_rect(
		get_canvas_item(), true, 
		Rect2(position + offset, size)
	)
	queue_redraw()

func _handle_mouse_button_down(event: InputEventMouseButton):
	var dirty = false
	
	# check for simultaneous inputs to perform different actions
	if dragging:
		if Input.is_key_pressed(KEY_SHIFT):
			var s: float = 0.0
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				s = 5.0
				dirty = true
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				s = -5.0
				dirty = true
			
			rotation = wrapf(rotation + (PI / 360.0 * s), 0, 2 * PI)
		else:
			var s: float = 0.0
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				s = 0.01
				dirty = true
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				s = -0.01
				dirty = true
			scale += Vector2(s, s)
			scale = clamp(scale, Vector2(0.01, 0.01), Vector2(5.0, 5.0))
		
	if event.button_index == MOUSE_BUTTON_LEFT:
		dragging = true
		drag_pressed.emit()
	
	return dirty

func _handle_mouse_motion(event: InputEventMouseMotion) -> bool:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var movement = event.relative
		if Input.is_key_pressed(KEY_SHIFT):
			free_rotation = Vector3(
				free_rotation.x,
				wrapf(free_rotation.y + (PI / 360.0 * movement.x), 0, 2 * PI),
				free_rotation.z
			)
		elif Input.is_key_pressed(KEY_CTRL):
			free_rotation = Vector3(
				wrapf(free_rotation.x + (PI / 360.0 * movement.y), 0, 2 * PI),
				free_rotation.y,
				free_rotation.z
			)
		elif Input.is_key_pressed(KEY_ALT):
			free_offset += movement
		else:
			global_position += movement
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
				if self.texture != null:
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
		transform_updated.emit(global_position, scale, rotation_degrees, free_offset, free_rotation)
		_update_rect()
