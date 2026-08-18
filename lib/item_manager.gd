extends Node

const VtModel = preload("res://lib/model/vt_model.gd")
const VtItem = preload("res://lib/items/vt_item.gd")

func about_item(path: String) -> Dictionary:
	if ModelManager.is_model(path):
		return {
			"name": path.get_basename(),
			"type": VtItem.ItemType.MODEL
		}
	elif DirAccess.dir_exists_absolute(path):
		return {
			"name": path.get_basename(),
			"type": VtItem.ItemType.ANIMATED
		}
	elif Image.load_from_file(path):
		return {
			"name": path.get_basename(),
			"type": VtItem.ItemType.IMAGE
		}
	return {}

func create_item(path: PackedStringArray) -> VtItem:
	assert(not path.is_empty())
	var vtitem = preload("res://lib/items/vt_item.tscn").instantiate()
	
	# APNG consists of multiple selected pngs
	if len(path) > 1:
		var frames: SpriteFrames = SpriteFrames.new()
		frames.set_animation_loop("default", true)
		for fp in path:
			var tex = ImageTexture.create_from_image(Image.load_from_file(fp))
			frames.add_frame(
				"default",
				tex
			)
				
		frames.set_animation_speed("default", 60.0 / frames.get_frame_count("default"))
	
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
	elif ModelManager.is_model(path[0]):
		var model = ModelManager.make_model(path[0])
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
		var render = Sprite2D.new()
		var texture: Texture2D
		texture = ImageTexture.create_from_image(Image.load_from_file(path[0]))
		if texture == null:
			return
		render.name = "Render"
		render.texture = texture
		render.centered = true
		vtitem.item_type = VtItem.ItemType.IMAGE
		vtitem.size = texture.get_size()
		vtitem.add_child(render)
		vtitem.render = render
		
	vtitem.path = path
	vtitem.display_name = path[0].get_file().substr(0, path[0].get_file().find(".", 1))
	
	return vtitem
