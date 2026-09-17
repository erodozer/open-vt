extends Node

const Files = preload("res://lib/utils/files.gd")
const DEFAULT_PROFILE_PATH = "user://default_profile.json"
const APP_SETTINGS_PATH = "user://settings.json"

# Filepath to currently open profile
var active_file: String = DEFAULT_PROFILE_PATH :
	set(v):
		var prev = active_file
		active_file = ProjectSettings.globalize_path(v)
		if prev != active_file:
			profile_changed.emit(active_file)

var _data = {}
var _dirty = false
@export var debug: bool = false

signal profile_changed(profile: String)

func _enter_tree() -> void:
	restore_app()
	get_tree().node_added.connect(
		func (n: Node):
			if n.is_in_group("persist") and n.has_method("load_settings"):
				n.load_settings(_data)
				if n.has_method("save_settings"):
					n.tree_exiting.connect(
						func ():
							n.save_settings(_data)
							_dirty = true
					)
			if n.has_method("hydrate"):
				n.ready.connect(
					n.hydrate.bind(_data),
					CONNECT_ONE_SHOT
				)
	)
	# limit writing to disk to at most once per frame when settings are persisted
	RenderingServer.frame_pre_draw.connect(
		func ():
			if _dirty:
				write_data()
	)
	
func _notification(what: int) -> void:
	# preserve last known app state to disk on close just in case
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_data()
		write_data()
		
## Writes global settings and active profile state to disk
func write_data(path = active_file):
	Files.write_json(path, _data)
	Files.write_json(APP_SETTINGS_PATH, {
		"profile": active_file,
		"debug": debug,
	})
	_dirty = false

## Used on application load.  Loads global settings and restores last used profile
func restore_app():
	var state = Files.read_json(APP_SETTINGS_PATH)
	
	var last_profile = state.get("profile", DEFAULT_PROFILE_PATH)
	change_profile(last_profile)

## loads data from a file and stores it in current app state
func load_data(path: String = active_file):
	var preferences = Files.read_json(path)
	
	_data = preferences

## clears the settings of the current profile and applies changes
func reset():
	_data = {}
	reload()
	
## loads data from file, applies it to the application, and sets the file path as the active profile
func change_profile(path: String = DEFAULT_PROFILE_PATH):
	load_data(path)
	reload()
	if not FileAccess.file_exists(path):
		path = DEFAULT_PROFILE_PATH
	active_file = path
	
## applies changes to visible nodes in the app
func reload():
	for n in get_tree().get_nodes_in_group("persist"):
		if n.has_method("load_settings"):
			n.load_settings(_data)
		
## persists node settings to stored state
func save_data():
	for n in get_tree().get_nodes_in_group("persist"):
		if n.has_method("save_settings"):
			n.save_settings(_data)
	_dirty = true
