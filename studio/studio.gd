extends Control

const Serializers = preload("res://lib/utils/serializers.gd")

func _ready() -> void:
	Preferences.load_data.call_deferred()
	if not Engine.is_embedded_in_editor():
		get_window().borderless = false
		
	DisplayServer.window_set_min_size(Vector2i(540,360), 0)
	
	await RenderingServer.frame_post_draw
	
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Preferences.save_data()

func save_settings(settings: Dictionary):
	var window_settings = settings.get("window", {})
	window_settings["size"] = Serializers.Vec2Serializer.to_json(get_window().size)
	settings["window"] = window_settings
	
func load_settings(settings: Dictionary):
	var window_prefs = settings.get("window", {})
	
	var default_size = Vector2i(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height")
	)
	var size = window_prefs.get("size", {})
	if size is Dictionary:
		get_window().size = Serializers.Vec2Serializer.from_json(size, default_size)
	get_window().move_to_center()
	
