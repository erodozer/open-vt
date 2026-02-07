extends Node

const VtModel = preload("res://lib/model/vt_model.gd")
const VtItem = preload("res://lib/items/vt_item.gd")

const FILE_DIR = "user://Items"

var item_cache: Array[String] = []
var png_items: Array[String] = []
var apng_items: Array[String] = []
var model_items: Array[String] = []

signal list_updated(items: Array)

func _ready() -> void:
	refresh_assets.call_deferred()
	
func refresh_assets():
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(FILE_DIR)):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FILE_DIR))
	
	png_items = []
	apng_items = []
	model_items = []
	
	for i in DirAccess.get_directories_at(FILE_DIR):
		var fp = FILE_DIR.path_join(i)
		
		var files = Array(DirAccess.get_files_at(fp))
		
		var is_model: bool = false
		var is_apng: bool = false

		for f in files:
			if f.ends_with(ModelManager["loader/l2d"].supported_extension()):
				is_model = true
				break
			if f.ends_with(".png"):
				is_apng = true
		
		if is_model:
			model_items.append(fp)
		elif is_apng:
			apng_items.append(fp)
		
	for i in DirAccess.get_files_at(FILE_DIR):
		var fp = FILE_DIR.path_join(i)
		if fp.ends_with(".png"):
			png_items.append(fp)
			
	# also include the ability to spawn any model as an item
	for i in DirAccess.get_directories_at(ModelManager["loader/l2d"].model_directory()):
		var fp = ModelManager["loader/l2d"].model_directory().path_join(i)
		model_items.append(fp)
		
	item_cache = png_items + apng_items + model_items
	
	list_updated.emit(item_cache)

func about_item(path: String) -> Dictionary:
	if path in png_items:
		return {
			"name": path.get_basename(),
			"type": VtItem.ItemType.IMAGE
		}
	elif path in apng_items:
		return {
			"name": path.get_basename(),
			"type": VtItem.ItemType.ANIMATED
		}
	elif path in model_items:
		return {
			"name": path.get_basename(),
			"type": VtItem.ItemType.MODEL
		}
	return {}

func create_item(path: String) -> VtItem:
	if path not in item_cache:
		return
	
	var vtitem = preload("res://lib/items/vt_item.tscn").instantiate()
	
	if path in png_items:
		var render = Sprite2D.new()
		var texture: Texture2D
		if ResourceLoader.has_cached(path):
			texture = ResourceLoader.load(path)
		else:
			texture = ImageTexture.create_from_image(Image.load_from_file(path))
			texture.take_over_path(path)
		render.name = "Render"
		render.texture = texture
		render.centered = true
		vtitem.item_type = VtItem.ItemType.IMAGE
		vtitem.size = texture.get_size()
		vtitem.add_child(render)
		vtitem.render = render
	elif path in apng_items:
		var frames: SpriteFrames
		
		if ResourceLoader.has_cached(path):
			frames = ResourceLoader.load(path)
		else:
			frames = SpriteFrames.new()
			frames.set_animation_loop("default", true)
			for i in DirAccess.get_files_at(path):
				var fp = path.path_join(i)
				if fp.ends_with(".png"):
					var tex = ImageTexture.create_from_image(Image.load_from_file(fp))
					frames.add_frame(
						"default",
						tex
					)
					
			frames.set_animation_speed("default", 60.0 / frames.get_frame_count("default"))
			frames.take_over_path(path)
		
		var size = Vector2.ZERO
		for f in range(frames.get_frame_count("default")):
			var tex = frames.get_frame_texture("default", f)
			size = Vector2(
				max(size.x, tex.get_size().x),
				max(size.y, tex.get_size().y)
			)
			
		var render = AnimatedSprite2D.new()
		render.sprite_frames = frames
		render.play("default")
		render.name = "Render"
		vtitem.size = size
		vtitem.add_child(render)
		vtitem.item_type = VtItem.ItemType.ANIMATED
		vtitem.render = render
	elif path in model_items:
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
