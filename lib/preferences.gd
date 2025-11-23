extends Node

const Files = preload("res://lib/utils/files.gd")
const UserSettings = "user://settings.json"

var _data = {}
@export var debug: bool = false

func _ready() -> void:
	get_tree().node_added.connect(
		func (n: Node):
			if n.has_method("hydrate"):
				n.ready.connect(
					n.hydrate.bind(_data),
					CONNECT_ONE_SHOT
				)
	)

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
	
	for n in get_tree().get_nodes_in_group("persist"):
		if n.has_method("load_settings"):
			n.load_settings(preferences)
			
	_data = preferences
		
func save_data():
	for n in get_tree().get_nodes_in_group("persist"):
		if n.has_method("save_settings"):
			n.save_settings(_data)
	
	Files.write_json(UserSettings, _data)
	
