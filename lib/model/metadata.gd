extends RefCounted

var name: String
var id: String
var studio_parameters: String # path to vtube.json file
var icon: String # path to icon image, as defined in vtube.json
var model: String # path to the moc3.json file as defined in vtube.json
var model_parameters: String # typically path to cdi3 file, as defined in moc3.json

func get_icon_texture() -> Texture2D:
	return null
