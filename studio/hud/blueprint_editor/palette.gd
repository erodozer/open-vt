extends Control

var _mapping: Dictionary[StringName, PackedScene] = {}

signal create_node(action: VtAction)

func _ready():
	tracker_options()
	arithmetic_options()
	
	for i in get_children():
		if i is MenuButton:
			i.get_popup().id_pressed.connect(
				func (x):
					var node = i.get_popup().get_item_metadata(x).call()
					create_node.emit(node)
			)
		elif i.has_meta("action"):
			var template: PackedScene = i.get_meta("action") 
			var action: VtAction = template.instantiate()
			_mapping[action.get_type()] = template
			var btn = i as Button
			btn.pressed.connect(
				func ():
					create_node.emit(template.instantiate())
			)
	
func tracker_options():
	var add_trackers: MenuButton = %AddTracker
	var idx = 0
	for i in Registry.parameter_groups():
		add_trackers.get_popup().add_item("Add %s Tracker" % [i])
		add_trackers.get_popup().set_item_metadata(
			idx,
			func ():
				var node = preload("res://lib/blueprints/inputs/tracker_input.tscn").instantiate()
				node.kind = i
				return node,
		)
		idx += 1
	
func arithmetic_options():
	var arithmetic: MenuButton = %Math
	var operators = preload("res://lib/blueprints/logic/arithmetic.gd").Operator
	arithmetic.get_popup().add_separator("Operators")
	var idx = 1
	for i in operators:
		arithmetic.get_popup().add_item(i)
		arithmetic.get_popup().set_item_metadata(
			idx,
			func ():
				var node = preload("res://lib/blueprints/logic/arithmetic.tscn").instantiate()
				node.operator = operators[i]
				return node,
		)
		idx += 1
	arithmetic.get_popup().add_separator("Functions")
	idx += 1
	arithmetic.get_popup().add_item("Remap")
	arithmetic.get_popup().set_item_metadata(
		idx,
		func ():
			var node = preload("res://lib/blueprints/logic/range_map.tscn").instantiate()
			return node,
	)
