extends CanvasLayer

const VtModel = preload("res://lib/model/vt_model.gd")
const VtItem = preload("res://lib/items/vt_item.gd")

const INDEX_RANGE = 30

@onready var active_model: VtModel = get_tree().get_first_node_in_group("vtmodel")

signal model_changed(model: VtModel)
signal item_added(item: VtItem)
signal update_order(objects: Array[Node])

static func _item_sorter(a, b):
	var x = 0
	var y = 0
	if a is VtItem:
		x = a.sort_order
	if b is VtItem:
		y = b.sort_order
	return x < y

func _reorder():
	var sorted = get_children().duplicate()
	sorted.sort_custom(_item_sorter)
	for i in range(len(sorted)):
		move_child(sorted[i], i)
	update_order.emit(sorted)

func spawn_model(model: VtModel):
	if active_model != null:
		remove_child(active_model)
		active_model.queue_free()
		
	active_model = model
	add_child(model)
	_reorder()
	
	# TODO if model had items pinned to it, load them in as well
	
	model_changed.emit(active_model)

func spawn_item(item: VtItem):
	item.position = get_viewport().get_texture().get_size() / 2
	
	# simply setting z_index does not work for control nodes, as Input order is not affected by it
	# instead we'll rely on child order in the stage to define the 
	add_child(item)
	_reorder()
	item_added.emit(item)

func remove_item(item: VtItem):
	pass
	
func clear_items():
	pass

func load_settings(data):
	if "active_model" in data:
		var mm = get_tree().get_first_node_in_group("system:model")
		var model = mm.make_model(data["active_model"])
		spawn_model(model)
	
func save_settings(data):
	data["active_model"] = active_model.model.id
	
