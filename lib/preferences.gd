extends Node

const Files = preload("res://lib/utils/files.gd")
const UserSettings = "user://settings.json"

var _data = {}
var _dirty = false
@export var debug: bool = false

func _enter_tree() -> void:
	load_data()
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
	RenderingServer.frame_pre_draw.connect(
		func ():
			if _dirty:
				write_data()
			_dirty = false
	)
	
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_data()
		write_data()
		
func write_data():
	Files.write_json(UserSettings, _data)

func get_setting(path: String, default: Variant) -> Variant:
	var parts = path.split(".")
	var cursor = _data
	for p in parts:
		if p in cursor:
			cursor = cursor.get(p)
		else:
			return default
	return cursor

func get_state():
	return _data.duplicate(true)

func load_data():
	var preferences = Files.read_json(UserSettings)
	
	_data = preferences
		
func save_data():
	for n in get_tree().get_nodes_in_group("persist"):
		if n.has_method("save_settings"):
			n.save_settings(_data)
	_dirty = true
