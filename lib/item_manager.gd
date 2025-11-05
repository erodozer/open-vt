extends Node

const VtModel = preload("res://lib/model/vt_model.gd")
const VtItem = preload("res://lib/items/vt_item.gd")

const FILE_DIR = "user://Items"
const MODEL_DIR = preload("res://lib/model_manager.gd").FILE_DIR

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

		for f in files:
			if f.ends_with(".model3.json"):
				is_live2d = true
				break
			if f.ends_with(".png"):
				is_apng = true
		
		if is_live2d:
			live2d_items.append(fp)
		elif is_apng:
			apng_items.append(fp)
		
	for i in DirAccess.get_files_at(FILE_DIR):
		var fp = FILE_DIR.path_join(i)
		if fp.ends_with(".png"):
			png_items.append(fp)
			
	# also include the ability to spawn any model as an item
	for i in DirAccess.get_directories_at(MODEL_DIR):
		var fp = MODEL_DIR.path_join(i)
		live2d_items.append(fp)
		
	item_cache = png_items + apng_items + live2d_items
	
	list_updated.emit(item_cache)

func create_item(path: String) -> VtItem:
	if path not in item_cache:
		return
	
	var vtitem = preload("res://lib/items/vt_item.tscn").instantiate()
	
	if path in png_items:
		var render = Sprite2D.new()
		var texture = ImageTexture.create_from_image(Image.load_from_file(path))
		render.name = "Render"
		render.texture = texture
		render.centered = true
		vtitem.item_type = VtItem.ItemType.IMAGE
		vtitem.size = texture.get_size()
		vtitem.add_child(render)
		vtitem.render = render
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
		var render = TextureRect.new()
		render.name = "Render"
		render.texture = ImageTexture.create_from_image(Image.load_from_file(path))
		vtitem.size = render.size
		vtitem.add_child(render)
		vtitem.item_type = VtItem.ItemType.ANIMATED
		vtitem.render = render
	elif path in live2d_items:
		var model = ModelManager.make_model(path)
		model.name = "Render"
		model.position = Vector2.INF
		add_child(model)
		await model.loaded
		if model.is_queued_for_deletion():
			return
		model.reparent(vtitem, false)
		# erase any settings from when it's a normal model
		model.position = Vector2.ZERO
		model.scale = Vector2.ONE
		model.rotation_degrees = 0
		# do not drag by the model itself, we want to drag the item
		model.locked = true
		
		vtitem.size = model.size
		vtitem.item_type = VtItem.ItemType.MODEL
		vtitem.render = model
	else:
		return
	
	vtitem.path = path
	vtitem.display_name = path.get_file()
	
	return vtitem
