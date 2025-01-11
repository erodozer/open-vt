extends PanelContainer

const ModelManager = preload("res://lib/model_manager.gd")

@onready var list = %ModelList

func _on_model_manager_list_updated(models: Array) -> void:
	for i in models:
		var btn = Button.new()
		btn.set_meta("model", i)
		btn.icon = ImageTexture.create_from_image(
			Image.load_from_file(i.icon)
		)
		btn.focus_mode = Control.FOCUS_NONE
		btn.tooltip_text = i.name
		btn.expand_icon = true
		btn.custom_minimum_size = Vector2(128, 128)
		btn.pressed.connect(
			func ():
				var manager = get_tree().get_first_node_in_group("system:model")
				if manager != null:
					manager.activate_model(i.id)
		)
		list.add_child(btn)

func _on_directory_button_pressed() -> void:
	OS.shell_open(ProjectSettings.globalize_path(ModelManager.MODEL_DIR))
