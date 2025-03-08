extends Node

const UserSettings = "user://settings.json"

var _data = {}

func _ready() -> void:
	get_tree().node_added.connect(
		func (n: Node):
			if n.has_method("_hydrate"):
				n._hydrate(_data)
	)

func load_data():
	if not FileAccess.file_exists(UserSettings):
		var f = FileAccess.open(UserSettings, FileAccess.WRITE_READ)
		f.store_string("{}")
		f.close()
	
	var preferences = JSON.parse_string(FileAccess.get_file_as_string(UserSettings))
	if preferences == null:
		return
		
	_data = JSON.to_native(preferences)
	for n in get_tree().get_nodes_in_group("persist"):
		if n.has_method("load_settings"):
			n.load_settings(_data)
		
func save_data():
	var f = FileAccess.open(UserSettings, FileAccess.WRITE_READ)
	
	var data = {}
	for n in get_tree().get_nodes_in_group("persist"):
		if n.has_method("save_settings"):
			n.save_settings(data)
	
	_data = data
	f.store_string(JSON.stringify(JSON.from_native(data)))
	f.close()
