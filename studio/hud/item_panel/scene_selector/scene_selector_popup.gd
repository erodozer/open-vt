extends PopupPanel

const VtItem = preload("res://lib/items/vt_item.gd")
const VtModel = preload("res://lib/model/vt_model.gd")
const Stage = preload("res://studio/stage/stage.gd")
const Math = preload("res://lib/utils/math.gd")
const Serializers = preload("res://lib/utils/serializers.gd")

const FILE_DIR = "user://ItemScenes"
const EXT = ".itemscene.json"

var btn_group: ButtonGroup

func get_selected_cfg() -> Dictionary:
	var selected = btn_group.get_pressed_button()
	if not selected:
		return {}
	return selected.get_meta("item_scene", {})

func get_scenes() -> Array:
	return Array(DirAccess.get_files_at(FILE_DIR)).filter(
		func (f: String):
			return f.ends_with(EXT)
	).map(
		func (f: String):
			var path = FILE_DIR.path_join(f)
			var data = JSON.parse_string(FileAccess.get_file_as_string(path))
			return {
				"ref": path,
				"id": data["SceneID"],
				"name": data["SceneName"],
				"group_name": StringName(data["SceneGroupName"]),
				"model": data["SceneModel"]
			}
	)

func load_item_scene(item_scene_cfg: Dictionary):
	var data = JSON.parse_string(FileAccess.get_file_as_string(item_scene_cfg.ref))
	
	var stage: Stage = get_tree().get_first_node_in_group("system:stage")
	stage.clear_items(StringName(item_scene_cfg.group_name))

	var idx = 0
	for item in data.get("Items", []):
		var i: VtItem = await ItemManager.create_item(
			ItemManager.FILE_DIR.path_join(item["ItemFileName"])
		)
		if i.item_type == VtItem.ItemType.ANIMATED:
			var render: AnimatedSprite2D = i.render
			render.speed_scale = item.get("FPS", 1.0) / render.sprite_frames.get_animation_speed("default")
		# convert Unity Units to Pixels
		var scale = item.get("Size", 0) / Math.UNITY_PPU
		i.scale = Vector2(-1 if item.get("IsFlipped", false) else 1, 1) * (1.0 + scale)
		i.rotation_degrees = item.get("Rotation", 0)
		i.sort_order = item.get("Order", idx)
		i.position = Math.unity_to_canvas(
			stage.get_viewport(),
			Serializers.Vec2Serializer.from_json(item.get("Position"))
		)
		stage.spawn_item(i, true, false)
		if item_scene_cfg.group_name:
			i.group_name = item_scene_cfg.group_name
		idx += 1
		
func save_item_scene(item_scene_cfg: String):
	pass

func _ready() -> void:
	var scenes = get_scenes()
	
	for i in %ItemList.get_children():
		i.queue_free()
		
	btn_group = ButtonGroup.new()
	btn_group.pressed.connect(_on_item_selected)
	for i in scenes:
		var btn = Button.new()
		btn.text = i.name
		btn.toggle_mode = true
		btn.button_group = btn_group
		btn.set_meta("item_scene", i)
		%ItemList.add_child(btn)
	if not btn_group.get_buttons().is_empty():
		btn_group.get_buttons()[0].button_pressed = true

func _on_load_button_pressed() -> void:
	await load_item_scene(get_selected_cfg())
	close_requested.emit()

func _on_item_selected(item: Node) -> void:
	var cfg = item.get_meta("item_scene")
	var data = JSON.parse_string(FileAccess.get_file_as_string(cfg.ref))
	
	%ModelName.text = cfg.model
	%GroupName.text = cfg.group_name
	
	for i in %SceneItems.get_children():
		i.queue_free()
	
	for i in data.get("Items", []):
		var meta = ItemManager.about_item(ItemManager.FILE_DIR.path_join(i["ItemFileName"]))
		if meta.is_empty():
			continue

		var row = preload("./item_row.tscn").instantiate()
		match meta.type:
			VtItem.ItemType.IMAGE:
				row.get_node("%Icon").texture = preload("../static_image.svg")
			VtItem.ItemType.ANIMATED:
				row.get_node("%Icon").texture = preload("../animated_image.svg")
			VtItem.ItemType.MODEL:
				row.get_node("%Icon").texture = preload("../motion.svg")
		
		row.get_node("%ModelName").text = i["ItemFileName"]
		if not i.get("PinnedTo", "").is_empty():
			row.get_node("%Pinned").text = i.get("PinnedTo")
		row.get_node("%Ordering").text = "%d" % i.get("Order", 0)
		%SceneItems.add_child(row)

func _on_close_requested() -> void:
	hide()

func _on_popup_hide() -> void:
	queue_free()
