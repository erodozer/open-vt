extends Node

const ModelMeta = preload("res://lib/model/metadata.gd")
const ModelExpression = preload("res://lib/model/expression.gd")
const VtModel = preload("res://lib/model/vt_model.gd")
const VtItem = preload("res://lib/items/vt_item.gd")

const FILE_DIR = "user://Items"

var item_cache: Array[String] = []
var png_items: Array[String] = []
var apng_items: Array[String] = []
var live2d_items: Array[String] = []

signal list_updated(items: Array)

func _ready() -> void:
	refresh_assets.call_deferred()
	
func refresh_assets():
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(FILE_DIR)):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FILE_DIR))
	
	png_items = []
	apng_items = []
	live2d_items = []
	
	for i in DirAccess.get_directories_at(FILE_DIR):
		var fp = FILE_DIR.path_join(i)
		
		var files = Array(DirAccess.get_files_at(fp))
		
		var is_live2d: bool = false
		var is_apng: bool = false

		var model_file: String
		for f in files:
			if f.ends_with(".model3.json"):
				is_live2d = true
				model_file = f
				break
			if f.ends_with(".png"):
				is_apng = true
		
		if is_live2d:
			live2d_items.append(model_file)
		elif is_apng:
			apng_items.append(fp)
		
	for i in DirAccess.get_files_at(FILE_DIR):
		var fp = FILE_DIR.path_join(i)
		if fp.ends_with(".png"):
			png_items.append(fp)
		
	item_cache = png_items + apng_items + live2d_items
	
	list_updated.emit(item_cache)

func create_item(path: String) -> VtItem:
	if path not in item_cache:
		return
	
	var vtitem = preload("res://lib/items/vt_item.tscn").instantiate()
	var item = vtitem.get_node("%Image")
	
	if path in png_items:
		item.texture = ImageTexture.create_from_image(Image.load_from_file(path))
	elif path in apng_items:
		var tex = AnimatedTexture.new()
		var frames = []
		for i in DirAccess.get_files_at(path):
			var fp = path.path_join(i)
			if fp.ends_with(".png"):
				frames.append(
					ImageTexture.create_from_image(Image.load_from_file(fp))
				)
		
		tex.frames = len(frames)
		for i in range(len(frames)):
			tex.set_frame_texture(i, frames[i])
		item.texture = tex
	elif path in live2d_items:
		var model = GDCubismUserModel.new()
		model.assets = path
		item.add_child(model)
		item.texture = model.get_texture()
	else:
		return
	
	vtitem.name = path.get_file()
	item.pivot_offset = -item.size / 2
	item.position = -item.size / 2
	
	return vtitem
