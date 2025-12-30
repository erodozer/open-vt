extends PopupPanel

const VtItem = preload("res://lib/items/vt_item.gd")

@onready var list = %List

func _ready():
	for i in ItemManager.item_cache:
		var btn = Button.new()
		btn.set_meta("model", i)
		var i_name = i.get_file().substr(0, i.get_file().find("."))
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
				
				var preview = preload("../preview/item_preview.tscn").instantiate()
				preview.item = item
				get_parent().add_child(preview)
				queue_free()
		)
		list.add_child(btn)

func _refresh_visibility():
	var search = %Search.text
	var show_png = %ImageType.button_pressed
	var show_apng = %AnimatedType.button_pressed
	var show_l2d = %ModelType.button_pressed
	
	for c in %List.get_children():
		var i = c.get_meta("model")
		var name_matches = c.text.to_lower().contains(search) if not search.is_empty() else true
		var type_matches = false
		if show_png and i in ItemManager.png_items:
			type_matches = true
		if show_apng and i in ItemManager.apng_items:
			type_matches = true
		if show_l2d and i in ItemManager.live2d_items:
			type_matches = true
		c.visible = name_matches and type_matches

func _on_search_text_changed(_new_text: String) -> void:
	_refresh_visibility()

func _on_image_type_toggled(_toggled_on: bool) -> void:
	_refresh_visibility()
	
func _on_animated_type_toggled(_toggled_on: bool) -> void:
	_refresh_visibility()

func _on_model_type_toggled(_toggled_on: bool) -> void:
	_refresh_visibility()

func _on_cancel_button_pressed() -> void:
	queue_free()

func _on_popup_hide() -> void:
	queue_free()

func _on_close_requested() -> void:
	hide()
