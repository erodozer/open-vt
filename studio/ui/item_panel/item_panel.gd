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
			
	stage.spawn_item(item)
	
func _on_item_popup_close_requested() -> void:
	item_configured.emit(false)

func _on_spawn_btn_pressed() -> void:
	item_configured.emit(true)

func _on_framerate_value_changed(value: float) -> void:
	if %Preview/Image.texture is AnimatedTexture:
		%Preview/Image.texture.speed_scale = value
