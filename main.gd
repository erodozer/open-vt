extends Node

@onready var preferences = get_tree().get_first_node_in_group("system:settings")

func _ready() -> void:
	preferences.load_data.call_deferred()
	get_window().borderless = false
	
func _on_model_changed(model: Node) -> void:
	preferences.save_data()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		preferences.save_data()

func save_settings(settings: Dictionary):
	var window_settings = settings.get("window", {})
	window_settings["position"] = get_window().position
	window_settings["size"] = get_window().size
	settings["window"] = window_settings
	
func load_settings(settings: Dictionary):
	var window_prefs = settings.get("window", {})
	
	var size = Vector2i(window_prefs.get("size", Vector2i(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height")
	)))
	#get_window().size = size
	#await get_tree().process_frame
	#get_window().move_to_center()
	
