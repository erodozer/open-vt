extends PanelContainer

const ModelManager = preload("res://lib/model_manager.gd")
const Stage = preload("res://lib/stage.gd")

@export var manager: ModelManager
@export var stage: Stage

@onready var list = %ModelList

func _refresh():
	manager.refresh_models()
	
func _on_model_manager_list_updated(models: Array) -> void:
	for f in list.get_children():
		f.queue_free()
	
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
				var model = manager.make_model(i.id)
				stage.spawn_model(model)
		)
		list.add_child(btn)

func _on_directory_button_pressed() -> void:
	OS.shell_open(ProjectSettings.globalize_path(ModelManager.MODEL_DIR))
