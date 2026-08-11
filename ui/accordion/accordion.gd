extends VBoxContainer
class_name Accordion

enum Mode {
	SINGLE,
	MULTI
}

@export var select_mode = Mode.SINGLE
@export var allow_deselect = true

var button_group = ButtonGroup.new()
var _folds: Dictionary = {} # section instance id -> Button

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
	var key = section.get_instance_id()
	var existing = _folds.get(key)
	if is_instance_valid(existing):
		return
	_folds.erase(key)

	var btn = Button.new()
	btn.text = section.name
	btn.toggle_mode = true
	btn.focus_mode = Control.FOCUS_NONE
	if select_mode == Mode.MULTI:
		btn.button_group = button_group
	btn.button_pressed = section.visible
	btn.toggled.connect(
		func (pressed):
			section.visible = pressed
	)
	_folds[key] = btn

	_attach_fold.call_deferred(btn, section, key)

func _attach_fold(btn: Button, section: Node, key: int) -> void:
	if not is_instance_valid(section) or section.get_parent() != self:
		btn.queue_free()
		_folds.erase(key)
		return
	add_child(btn)
	move_child(btn, section.get_index())
