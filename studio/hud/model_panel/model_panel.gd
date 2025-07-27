extends PanelContainer

const ModelManager = preload("res://lib/model_manager.gd")
const Stage = preload("res://lib/stage.gd")

@onready var manager: ModelManager = get_tree().get_first_node_in_group("system:model")
@onready var stage: Stage = get_tree().get_first_node_in_group("system:stage")
@onready var list = %ModelList

func _ready() -> void:
	if manager:
		manager.list_updated.connect(_on_model_manager_list_updated)

func _refresh():
	manager.refresh_models()
	
func _on_model_manager_list_updated(models: Array) -> void:
	for f in list.get_children():
		f.queue_free()
	
	for i in models:
		var btn = Button.new()
		btn.set_meta("model", i)
		btn.icon = i.icon
		btn.theme_type_variation = "ImageButton"
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
