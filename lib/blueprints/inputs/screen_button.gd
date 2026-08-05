extends "../vt_action.gd"

@onready var mapping = %Mapping.get_children()
@export var button_group: ButtonGroup

func _ready() -> void:
	var controller = get_tree().get_first_node_in_group("system:hotkey")
	controller.pressed.connect(_on_press)
	
func get_type() -> StringName:
	return &"screen_button"
	
func serialize():
	var pressed = button_group.get_pressed_button()
	var index = -1
	if pressed != null:
		index = pressed.get_index()
	return {
		"button": index
	}
	
func deserialize(data: Dictionary):
	if data.get("button", -1) >= 0:
		button_group.get_buttons()[data.button].set_pressed_no_signal(true)
	
func get_input_slot_by_port(port: int) -> int:
	return -1
	
func get_input_port_by_name(slot: StringName) -> int:
	return -1
	
func get_output_port_by_name(slot: StringName) -> int:
	match slot.to_lower():
		"pressed":
			return 0
		_:
			return -1

func get_output_slot_by_port(port: int) -> int:
	match port:
		0:
			return 1
		_:
			return -1
	
func _on_press(idx: int):
	if mapping[idx].button_pressed:
		slot_updated.emit(0)
	
func _on_updated(_slot_index: int) -> void:
	var t = create_tween()
	t.tween_property(
		%Pressed/ColorRect, "modulate", Color.WHITE, 0.15
	).from(Color.TRANSPARENT)
	t.tween_property(
		%Pressed/ColorRect, "modulate", Color.TRANSPARENT, 0.1
	)
