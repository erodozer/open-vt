extends Control

const VtAction = preload("res://lib/blueprints/vt_action.gd")

var _mapping: Dictionary[StringName, PackedScene] = {}

signal create_node(action: VtAction)

func _ready():
	for i in get_children():
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
