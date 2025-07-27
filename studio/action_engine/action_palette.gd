extends PanelContainer

const VtAction = preload("res://studio/action_engine/graph/vt_action.gd")

var _mapping: Dictionary[StringName, PackedScene] = {}

signal create_node(action: VtAction)

func _ready():
	for i in %Buttons.get_children():
		if not i.has_meta("action"):
			continue
		var btn: Button = i
		var template: PackedScene = i.get_meta("action") 
		var action: VtAction = template.instantiate()
		_mapping[action.get_type()] = template
		btn.pressed.connect(
			func ():
				create_node.emit(template.instantiate())
		)

func create(type: StringName):
	assert(type in _mapping)
	return _mapping[type].instantiate()
