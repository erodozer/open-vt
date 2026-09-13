extends Control

func _ready() -> void:
	Preferences.load_data.call_deferred()
	if not Engine.is_embedded_in_editor():
		get_window().borderless = false

	var scale = DisplayServer.screen_get_scale()
	DisplayServer.window_set_min_size(Vector2i(540,360) * scale, 0)

	await RenderingServer.frame_post_draw
	
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Preferences.save_data()

func save_settings(settings: Dictionary):
	var scale = DisplayServer.screen_get_scale()

	var window_settings = settings.get("window", {})
	window_settings["position"] = get_window().position

	var size = Vector2i(get_window().size / scale)
	window_settings["size"] = [size.x, size.y]
	settings["window"] = window_settings
	
func load_settings(settings: Dictionary):
	var scale = DisplayServer.screen_get_scale()

	var size = Vector2i(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height")
	);

	var window_prefs = settings.get("window", {})
	var saved_size = window_prefs.get("size", [])
	if saved_size is Array and saved_size.size() == 2:
		size.x = saved_size[0]
		size.y = saved_size[1]
	
	var win: Window = get_window()

	win.size = Vector2i(size * scale)
	win.content_scale_factor = scale
	print("Initial window size: ", size)
	print("Scale: ", scale, " ", win.size)
	await get_tree().process_frame
	get_window().move_to_center()
