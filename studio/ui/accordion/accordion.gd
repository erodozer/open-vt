extends VBoxContainer
class_name Accordion

enum Mode {
	SINGLE,
	MULTI
}

@export var select_mode = Mode.SINGLE
@export var allow_deselect = true

func _ready() -> void:
	var button_group = ButtonGroup.new()
	button_group.allow_unpress = allow_deselect
	
	var items = get_children()
	for i in items:
		var btn = Button.new()
		btn.text = i.name
		btn.toggle_mode = true
		if select_mode == Mode.MULTI:
			btn.button_group = button_group
		add_child(btn)
		move_child(btn, i.get_index())
		btn.button_pressed = i.visible
		btn.toggled.connect(
			func (pressed):
				i.visible = pressed
		)
	
