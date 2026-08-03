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
		if i is MenuButton:
			i.get_popup().id_pressed.connect(
				func (x):
					var node = template.instantiate()
					node.kind = i.get_popup().get_item_metadata(x)
					create_node.emit(node)
			)
		else:
			btn.pressed.connect(
				func ():
					create_node.emit(template.instantiate())
			)
	
	var add_trackers: MenuButton = %AddTracker
	var idx = 0
	for i in Registry.parameter_groups():
		add_trackers.get_popup().add_item("Add %s Tracker" % [i])
		add_trackers.get_popup().set_item_metadata(idx, i)
		idx += 1
