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
	var btn = preload("./accordion_button.tscn").instantiate()
	btn.text = section.name
	btn.button_pressed = section.visible
	if select_mode == Mode.MULTI:
		btn.button_group = button_group
	btn.link = section
	
	# add sibling before
	add_child(btn)
	move_child(btn, section.get_index())
	
