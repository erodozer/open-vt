extends Node

const VtItem = preload("res://lib/items/vt_item.gd")
const VtModel = preload("res://lib/model/vt_model.gd")
const Stage = preload("res://studio/stage/stage.gd")
const Math = preload("res://lib/utils/math.gd")
const Serializers = preload("res://lib/utils/serializers.gd")
const Files = preload("res://lib/utils/files.gd")

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

func load_item_scene():
	var stage: Stage = get_tree().get_first_node_in_group("system:stage")
	var group_name = %GroupName.text
	stage.clear_items(group_name)
	
	var idx = 0
	for i in %SceneItems.get_children():
		var cfg = i.get_meta("cfg", {})
		var item: VtItem = await ItemManager.create_item(i.get_meta("filepath"))
		if i.get_meta("item_type") == VtItem.ItemType.ANIMATED:
			var render: AnimatedSprite2D = i.render
			render.speed_scale = cfg.get("FPS", 1.0) / render.sprite_frames.get_animation_speed("default")
		# convert Unity Units to Pixels
		var scale = cfg.get("Size", 0) / Math.UNITY_PPU
		item.scale = Vector2(-1 if cfg.get("IsFlipped", false) else 1, 1) * (1.0 + scale)
		item.rotation_degrees = cfg.get("Rotation", 0)
		item.sort_order = cfg.get("Order", idx)
		item.position = Math.unity_to_canvas(
			stage.get_viewport(),
			Serializers.Vec2Serializer.from_json(cfg.get("Position"))
		)
		stage.spawn_item(item, true, false)
		if group_name:
			item.group_name = group_name
		idx += 1

func _on_load_button_pressed() -> void:
	await load_item_scene()
	_on_close_requested()

func _on_file_dialog_file_selected(path: String) -> void:
	%FileDialog.hide()
	
	var cfg = Files.read_json(path)
	
	%ModelName.text = cfg.get("SceneModel", "")
	%GroupName.text = cfg.get("SceneGroupName", "")
	
	for i in %SceneItems.get_children():
		%SceneItems.remove_child(i)
		i.queue_free()
	
	for i in cfg.get("Items", []):
		# OVT supported absolute path
		var item_file = i.get("ItemPath", "")
		if not item_file:
			# matching VTS for compatibility
			# fallback to looking in an Items directory relative to the item scene
			# otherwise load from the user data folder
			var item_file_name = i.get("ItemFileName")
			item_file = path.get_base_dir().get_base_dir().path_join("Items").path_join(item_file_name)
			if not FileAccess.file_exists(item_file):
				item_file = ProjectSettings.globalize_path("user://Items".path_join(item_file_name))
			
		var meta = ItemManager.about_item(item_file)
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
		row.get_node("%Ordering").value = i.get("Order", 0)
		row.set_meta("filepath", PackedStringArray([item_file]))
		row.set_meta("cfg", i)
		row.set_meta("item_type", meta.type)
		%SceneItems.add_child(row)
	
	%ScenePreview.show()

func _on_close_requested() -> void:
	queue_free()
