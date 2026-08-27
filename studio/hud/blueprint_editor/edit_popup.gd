extends AcceptDialog

const Blueprint = preload("res://lib/blueprints/blueprint.gd")

var graph: Blueprint

func _ready() -> void:
	add_button("Delete", true, "Delete")
	add_cancel_button("Cancel")
	
	%ProfileName.text = graph.name
	%ProfileEnabled.set_pressed_no_signal(graph.process_mode != PROCESS_MODE_DISABLED)
	
	position = Vector2i(get_visible_rect().size / 2) + (size / 2)
	
	# fix theming
	var panel: Panel = get_child(0, true)
	panel.theme_type_variation = "WindowPanel"
	panel.remove_theme_stylebox_override("panel")
	
func _on_custom_action(action: StringName) -> void:
	if action == "Delete":
		graph.get_parent().remove_child(graph)
		graph.queue_free()
	close_requested.emit()

func _on_confirmed() -> void:
	graph.name = %ProfileName.text
	graph.process_mode = PROCESS_MODE_INHERIT if %ProfileEnabled.button_pressed else PROCESS_MODE_DISABLED
	close_requested.emit()

func _on_close_requested() -> void:
	queue_free()

func _on_canceled() -> void:
	close_requested.emit()
