extends Control

const ModelMeta = preload("res://lib/model/vt_model.gd").ModelMeta

var model : ModelMeta

signal pressed

func _ready():
	%Icon.texture = model.icon_texture
	%Label.text = model.name
	%LastSaved.text = "Last Saved:\n%s" % Time.get_datetime_string_from_unix_time(model.last_updated)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed == true and event.button_index == MOUSE_BUTTON_LEFT:
			pressed.emit()
