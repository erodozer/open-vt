extends Control

const VtModel = preload("res://lib/model/vt_model.gd")

@onready var anchor: Node2D = get_parent()

func _ready() -> void:
	set_process_unhandled_input(true)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if Input.is_key_pressed(KEY_CTRL):
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				anchor.rotation_degrees += 1
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				anchor.rotation_degrees -= 1
			elif event.button_index == MOUSE_BUTTON_MIDDLE:
				anchor.rotation_degrees = 0
			anchor.rotation_degrees = wrapi(anchor.rotation_degrees, 0, 359)
		else:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				scale += Vector2(0.01, 0.01)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				scale -= Vector2(0.01, 0.01)
			scale = clamp(scale, Vector2(0.1, 0.1), Vector2(5, 5))
		
	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			anchor.position += event.screen_relative
