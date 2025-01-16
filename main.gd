extends Control

const UserSettings = "user://settings.json"

func _ready() -> void:
	_load_preferences.call_deferred()

func _on_model_changed(model: Node) -> void:
	model.reparent(self)
	_save_preferences()

func _on_camera_panel_toggle_bg_transparency(enabled: bool) -> void:
	get_tree().root.transparent_bg = enabled
	%BgFill.visible = not enabled

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_preferences()

func _load_preferences():
	if not FileAccess.file_exists(UserSettings):
		var f = FileAccess.open(UserSettings, FileAccess.WRITE_READ)
		f.store_string("{}")
		f.close()
	
	var preferences = JSON.parse_string(FileAccess.get_file_as_string(UserSettings))
	
	for n in get_tree().get_nodes_in_group("persist"):
		n.load_settings(preferences)
		
func _save_preferences():
	var f = FileAccess.open(UserSettings, FileAccess.WRITE_READ)
	
	var data = {}
	for n in get_tree().get_nodes_in_group("persist"):
		n.save_settings(data)
		
	f.store_string(JSON.stringify(data))
	f.close()
