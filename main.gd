extends Node

@onready var preferences = get_tree().get_first_node_in_group("system:settings")

func _ready() -> void:
	preferences.load_data.call_deferred()
	get_window().borderless = false
	
func _on_model_changed(model: Node) -> void:
	preferences.save_data()

func _on_camera_panel_toggle_bg_transparency(enabled: bool) -> void:
	get_tree().root.transparent_bg = enabled
	%Bg.visible = not enabled

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		preferences.save_data()

func save_settings(settings: Dictionary):
	settings["window"] = {
		"position": get_window().position,
		"size": get_window().size
	}
	
func load_settings(settings: Dictionary):
	var window_prefs = settings.get("window", {})
	
	var size = Vector2i(window_prefs.get("size", Vector2i(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height")
	)))
	#get_window().size = size
	#await get_tree().process_frame
	#get_window().move_to_center()
	
