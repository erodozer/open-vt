extends VBoxContainer
class_name Accordion

enum Mode {
	SINGLE,
	MULTI
}

@export var select_mode = Mode.SINGLE
@export var allow_deselect = true

var button_group = ButtonGroup.new()

func _ready() -> void:
	button_group.allow_unpress = allow_deselect
	
	for i in get_children():
		add_fold(i)
		
	child_entered_tree.connect(
		func (node):
			if node.get_parent() != self:
				return
			# only allow collapsing nodes with children
			if node.get_child_count() > 0:
				add_fold(node)
	)
	
func add_fold(section: Node):
	var btn = Button.new()
	btn.text = section.name
	btn.toggle_mode = true
	btn.focus_mode = Control.FOCUS_NONE
	if select_mode == Mode.MULTI:
		btn.button_group = button_group
	add_child(btn)
	move_child(btn, section.get_index())
	btn.button_pressed = section.visible
	btn.toggled.connect(
		func (pressed):
			section.visible = pressed
	)
	
