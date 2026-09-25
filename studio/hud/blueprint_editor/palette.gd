extends Control

const VtModel = preload("res://lib/model/vt_model.gd")

var _mapping: Dictionary[StringName, PackedScene] = {}

signal create_node(action: VtAction)

var model: VtModel :
	set(m):
		model = m
		for i in get_children():
			if i.get_meta("is_3d", false) and not model.is_3D:
				i.visible = false
			if i.get_meta("is_2d", false) and model.is_3D:
				i.visible = false

func _ready():
	tracker_options()
	store_options()
	arithmetic_options()
	toggle_options()
	smoothing_options()
	
	for i in get_children():
		if i.has_meta("action"):
			var template: PackedScene = i.get_meta("action") 
			var action: VtAction = template.instantiate()
			_mapping[action.get_type()] = template
			var btn = i as Button
			btn.pressed.connect(
				func ():
					create_node.emit(template.instantiate())
			)
	
func _handle_popup(selected:int, popup: PopupMenu):
	var type = popup.get_item_metadata(selected)
	if type is Callable:
		var node = type.call()
		create_node.emit(node)
	
func tracker_options():
	var add_trackers: MenuButton = %AddTracker
	var menu: PopupMenu = add_trackers.get_popup()
	var idx = 0
	menu.id_pressed.connect(_handle_popup.bind(menu))
	for i in Registry.parameter_groups():
		menu.add_item("Add %s Tracker" % [i])
		menu.set_item_metadata(
			idx,
			func ():
				var node = preload("res://lib/blueprints/inputs/tracker_input.tscn").instantiate()
				node.kind = i
				return node,
		)
		idx += 1
	menu.add_item("Add XR Tracker")
	menu.set_item_metadata(
		idx,
		func ():
			var node = preload("res://lib/blueprints/inputs/xr_tracker_input.tscn").instantiate()
			return node,
	)
	
func arithmetic_options():
	var arithmetic: MenuButton = %Math
	var menu: PopupMenu = arithmetic.get_popup()
	
	var value_types = preload("res://lib/blueprints/inputs/value_emitter.gd").Kind
	var submenu = PopupMenu.new()
	submenu.id_pressed.connect(_handle_popup.bind(submenu))
	menu.add_submenu_node_item("Data", submenu)
	var idx = 0
	for i in value_types:
		submenu.add_item(i)
		submenu.set_item_metadata(
			idx,
			func ():
				var node = preload("res://lib/blueprints/inputs/value_emitter.tscn").instantiate()
				node.kind = value_types[i]
				return node,
		)
		idx += 1
	submenu.add_separator("Compose")
	idx += 1
	var composition_types = preload("res://lib/blueprints/logic/compose.gd").Kind
	for kind in composition_types:
		submenu.add_item(kind)
		submenu.set_item_metadata(
			idx,
			func ():
				var node = preload("res://lib/blueprints/logic/compose.tscn").instantiate()
				node.kind = composition_types[kind]
				return node,
		)
		idx += 1
	submenu.add_separator("Decompose")
	idx += 1
	var decomposition_types = preload("res://lib/blueprints/logic/decompose.gd").Kind
	for kind in decomposition_types:
		submenu.add_item(kind)
		submenu.set_item_metadata(
			idx,
			func ():
				var node = preload("res://lib/blueprints/logic/decompose.tscn").instantiate()
				node.kind = decomposition_types[kind]
				return node,
		)
		idx += 1
	
	var operators = preload("res://lib/blueprints/logic/arithmetic.gd").Operator
	submenu = PopupMenu.new()
	submenu.id_pressed.connect(_handle_popup.bind(submenu))
	menu.add_submenu_node_item("Operators", submenu)
	idx = 0
	for i in operators:
		submenu.add_item(i)
		submenu.set_item_metadata(
			idx,
			func ():
				var node = preload("res://lib/blueprints/logic/arithmetic.tscn").instantiate()
				node.operator = operators[i]
				return node,
		)
		idx += 1
		
	submenu = PopupMenu.new()
	submenu.id_pressed.connect(_handle_popup.bind(submenu))
	menu.add_submenu_node_item("Functions", submenu)
	submenu.add_item("Remap")
	submenu.set_item_metadata(
		0,
		func ():
			var node = preload("res://lib/blueprints/logic/range_map.tscn").instantiate()
			return node,
	)
	submenu.add_item("Eval")
	submenu.set_item_metadata(
		1,
		func ():
			var node = preload("res://lib/blueprints/logic/evaluator.tscn").instantiate()
			return node,
	)
	
	
func toggle_options():
	var toggler: MenuButton = %Toggler
	var popup = toggler.get_popup()
	popup.id_pressed.connect(_handle_popup.bind(popup))
	popup.set_item_metadata(
		0,
		func ():
			var node = preload("res://lib/blueprints/logic/toggle_state.tscn").instantiate()
			return node,
	)
	popup.set_item_metadata(
		1,
		func ():
			var node = preload("res://lib/blueprints/logic/toggle_group.tscn").instantiate()
			return node,
	)

func smoothing_options():
	var menu: MenuButton = %Smoothing
	var popup = menu.get_popup()
	popup.id_pressed.connect(_handle_popup.bind(popup))
	popup.set_item_metadata(
		0,
		func ():
			var node = preload("res://lib/blueprints/logic/smoothing.tscn").instantiate()
			return node,
	)
	popup.set_item_metadata(
		1,
		func ():
			var node = preload("res://lib/blueprints/logic/tweener.tscn").instantiate()
			return node,
	)

func store_options():
	var menu: MenuButton = %DataStore
	var popup = menu.get_popup()
	popup.id_pressed.connect(_handle_popup.bind(popup))
	
	popup.set_item_metadata(
		0,
		func ():
			var node = preload("res://lib/blueprints/inputs/metastore_input.tscn").instantiate()
			return node,
	)
	popup.set_item_metadata(
		1,
		func ():
			var node = preload("res://lib/blueprints/outputs/metastore_output.tscn").instantiate()
			return node,
	)
