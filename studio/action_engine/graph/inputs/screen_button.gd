extends "../vt_action.gd"

const ActionController = preload("res://studio/action_engine/action_controller.gd")

@onready var mapping = %Mapping.get_children()

func _ready() -> void:
	var controller: ActionController = get_tree().get_first_node_in_group("system:hotkey")
	controller.pressed.connect(_on_press)
	
func _on_press(idx: int):
	if mapping[idx].button_pressed:
		slot_updated.emit(0)
	
func _on_slot_updated(_slot_index: int) -> void:
	var t = create_tween()
	t.tween_property(
		%Pressed/ColorRect, "modulate", Color.WHITE, 0.15
	).from(Color.TRANSPARENT)
	t.tween_property(
		%Pressed/ColorRect, "modulate", Color.TRANSPARENT, 0.1
	)
