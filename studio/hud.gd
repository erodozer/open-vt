extends Control

const UserSettings = "user://settings.json"

var open
var group: ButtonGroup

func _ready() -> void:
	group = %ParameterBtn.button_group
	group.pressed.connect(
		func (button):
			if open != null:
				open.create_tween().tween_property(
					open,
					"position",
					Vector2(size.x, 0),
					0.3
				).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC).from(Vector2(size.x - open.size.x, 0))
			
			var panel = null
			if button != null and button.button_pressed:
				panel = button.get_node(button.get_meta("panel"))
				panel.create_tween().tween_property(
					panel,
					"position",
					Vector2(size.x - panel.size.x, 0),
					0.3
				).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC).from(Vector2(size.x, 0))
				
			open = panel
	)

func _load_preferences():
	if not FileAccess.file_exists(UserSettings):
		var f = FileAccess.open(UserSettings, FileAccess.WRITE_READ)
		f.store_string("{}")
		f.close()
	
	var preferences = JSON.parse_string(FileAccess.get_file_as_string(UserSettings))
	var model = preferences.get("active_model", "")
	if model:
		$ModelManager.activate_model(model)

func _on_transparency_toggled(toggled_on: bool) -> void:
	%BgFill.visible = !toggled_on

func _on_model_manager_model_changed(_model: Node) -> void:
	%ParameterBtn.button_pressed = true

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if Input.is_key_pressed(KEY_CTRL) and Input.is_key_pressed(KEY_H):
			$HUD.visible = !$HUD.visible
			accept_event()
