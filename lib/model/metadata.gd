extends RefCounted

var name: String
## unique model identifier
var id: String
## path to vtube.json file
var studio_parameters: String
## path to icon image, as defined in vtube.json
var icon: String
## path to the moc3.json file as defined in vtube.json
var model: String
## typically the path to cdi3 file, as defined in moc3.json
var model_parameters: String

func get_icon_texture() -> Texture2D:
	return null
