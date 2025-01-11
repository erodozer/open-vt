extends Control

@onready var preview = %Icon
@onready var label = %Label

var model

signal selected(model)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			selected.emit(model)
