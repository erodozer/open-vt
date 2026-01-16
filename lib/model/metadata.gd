extends RefCounted

var name: String
var format: String
var path: String
## unique model identifier
var id: String
## path to vtube.json file
var studio_parameters: String
## path to ovt.json file
var openvt_parameters: String
## path to icon image, as defined in vtube.json
var icon: String
var icon_texture: Texture2D :
	get():
		if icon.is_empty():
			return load("res://branding/monochrome.svg")
		if ResourceLoader.has_cached(icon):
			return load(icon)
		
		var texture = ImageTexture.create_from_image(Image.load_from_file(icon))
		texture.take_over_path(icon)
		return texture
	
## path to the moc3.json file as defined in vtube.json
var model: String
## typically the path to cdi3 file, as defined in moc3.json
var model_parameters: String
## path to the physics3.json file that l2d models may have
var physics: String
## time the model was last opened/saved
var last_updated: int

func get_icon_texture() -> Texture2D:
	return null
