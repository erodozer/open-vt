extends "res://studio/hud/side_panel.gd"

const Stage = preload("res://studio/stage/stage.gd")
const Preview = preload("./model_selector.tscn")

@onready var stage: Stage = get_tree().get_first_node_in_group(Stage.GROUP_NAME)
@onready var list = %ModelList

func teardown():
	for f in list.get_children():
		f.queue_free()

func setup():
	var models = ModelManager.refresh_models()
	
	for f in list.get_children():
		f.queue_free()
	
	for i in models:
		var btn = Preview.instantiate()
		btn.model = i
		btn.pressed.connect(
			func ():
				var model = ModelManager.make_model(i.id)
				stage.spawn_model(model)
		)
		list.add_child(btn)

func _on_directory_button_pressed() -> void:
	OS.shell_open(ProjectSettings.globalize_path(ModelManager.FILE_DIR))
