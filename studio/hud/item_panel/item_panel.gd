extends PanelContainer

const VtItem = preload("res://lib/items/vt_item.gd")
const VtModel = preload("res://lib/model/vt_model.gd")
const Stage = preload("res://studio/stage/stage.gd")

@onready var stage: Stage = get_tree().get_first_node_in_group("system:stage")
@onready var list = %List

signal item_configured(add_item: bool)

func _ready():
	ItemManager.list_updated.connect(_on_item_manager_list_updated)
	
	if stage:
		stage.model_changed.connect(_on_stage_model_changed)
		stage.item_added.connect(_on_stage_item_added)
		
func _on_item_manager_list_updated(models: Array) -> void:
	for f in list.get_children():
		f.queue_free()
	
	for i in models:
		var btn = Button.new()
		btn.set_meta("model", i)
		var i_name = i.get_file().substr(0, i.find("."))
		btn.name = i_name
		btn.text = i_name
		btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.focus_mode = Control.FOCUS_NONE
		# btn.expand_icon = true
		btn.custom_minimum_size = Vector2(128, 32)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(
			func ():
				var item = await ItemManager.create_item(i)
				assert(item != null, "could not load item")
				_show_configuration(item)
		)
		list.add_child(btn)

func _on_directory_button_pressed() -> void:
	OS.shell_open(ProjectSettings.globalize_path(ItemManager.FILE_DIR))

func _show_configuration(item: VtItem) -> void:
	%Preview.add_child(item)
	
	%ZIndex/Value.value = 0
	%FrameRate/Value.value = 10
	%Pin/Value.button_pressed = false
	
	%Modal.show()
	%ItemSelectPopup.hide()
	%ItemPopup.show()
	
	%Preview/Camera2D.position = Vector2.ZERO
	var ratio = min(
			%Preview.get_size().x / item.size.x,
			%Preview.get_size().y / item.size.y,
			1.0
		)
	%Preview/Camera2D.zoom = Vector2.ONE * ratio
	
	var add = await item_configured
	
	%ItemPopup.hide()
	%Modal.hide()
	
	if not add:
		item.queue_free()
		return
	
	#if tex is AnimatedTexture:
	#	tex.speed_scale = %FrameRate/Value.value
	
	item.sort_order = int(%ZIndex/Value.value)
	item.pinnable = %Pin/Value.button_pressed
	
	%Preview.remove_child(item)
	stage.spawn_item(item)
	
func _on_spawn_btn_pressed() -> void:
	item_configured.emit(true)

func _on_stage_item_added(item: VtItem) -> void:
	var row = preload("./item_row.tscn").instantiate()
	row.item = item
	
	%StageItems.add_child(row)

func _on_stage_model_changed(model: VtModel) -> void:
	for i in %StageItems.get_children():
		if i.item != null and i.item is VtModel:
			i.queue_free()

	var row = preload("./item_row.tscn").instantiate()
	row.item = model
	
	%StageItems.add_child(row)

func _on_stage_update_order(objects: Array[Node]) -> void:
	for i in range(len(objects)):
		var o = objects[i]
		for c in %StageItems.get_children():
			if c.item == o:
				%StageItems.move_child(c, i)

func _on_add_button_pressed() -> void:
	%ItemSearch.text = ""
	%Modal.show()
	%ItemSelectPopup.show()
	
	await item_configured
	
	%ItemSelectPopup.hide()
	%Modal.hide()
	_on_item_search_text_changed("")

func _on_item_search_text_changed(new_text: String) -> void:
	var txt = new_text.to_lower().strip_edges()
	for i in %List.get_children():
		i.visible = i.name.to_lower().contains(new_text) if not txt.is_empty() else true

func _on_clear_button_pressed() -> void:
	for i in %StageItems.get_children():
		if i.item is VtItem:
			i.item.queue_free()
			i.queue_free()
		
func _on_cancel_button_pressed() -> void:
	item_configured.emit(false)
