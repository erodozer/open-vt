extends PanelContainer

const ItemManager = preload("res://lib/item_manager.gd")
const VtItem = preload("res://lib/items/vt_item.gd")
const Stage = preload("res://lib/stage.gd")

@export var manager: ItemManager
@export var stage: Stage
@onready var list = %List

signal item_configured(add_item: bool)

func _on_item_manager_list_updated(models: Array) -> void:
	for f in list.get_children():
		f.queue_free()
	
	for i in models:
		var btn = Button.new()
		btn.set_meta("model", i)
		btn.text = i.get_file()
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.focus_mode = Control.FOCUS_NONE
		# btn.expand_icon = true
		btn.custom_minimum_size = Vector2(128, 32)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(
			func ():
				var item = manager.create_item(i)
				_show_configuration(item)
		)
		list.add_child(btn)

func _on_directory_button_pressed() -> void:
	OS.shell_open(ProjectSettings.globalize_path(ItemManager.FILE_DIR))

func _show_configuration(item: VtItem) -> void:
	var tex = item.get_node("Image").texture
	%Preview/Image.texture = tex
	
	%ZIndex/Value.value = 0
	%FrameRate/Value.value = 10
	
	%Modal.show()
	%ItemPopup.show()
	
	await item_configured
	
	%ItemPopup.hide()
	%Modal.hide()
	
	if not item_configured:
		item.queue_free()
		return
	
	if tex is AnimatedTexture:
		tex.speed_scale = %FrameRate/Value.value
	
	item.sort_order = int(%ZIndex/Value.value)
	item.pinnable = %Pin/Value.button_pressed
			
	stage.spawn_item(item)
	
func _on_item_popup_close_requested() -> void:
	item_configured.emit(false)

func _on_spawn_btn_pressed() -> void:
	item_configured.emit(true)

func _on_framerate_value_changed(value: float) -> void:
	if %Preview/Image.texture is AnimatedTexture:
		%Preview/Image.texture.speed_scale = value

func _on_stage_item_added(item: Node2D) -> void:
	var row = preload("./item_row.tscn").instantiate()
	row.item = item
	
	%StageItems.add_child(row)

func _on_stage_model_changed(model: Node2D) -> void:
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
	%Modal.show()
	%ItemSelectPopup.show()
	
	await item_configured
	
	%ItemSelectPopup.hide()
	%Modal.hide()
