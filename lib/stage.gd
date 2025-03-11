extends Node

const VtModel = preload("res://lib/model/vt_model.gd")
const VtItem = preload("res://lib/items/vt_item.gd")

const INDEX_RANGE = 30

@onready var preferences = get_tree().get_first_node_in_group("system:settings")
@onready var active_model: VtModel = get_tree().get_first_node_in_group("vtmodel")
@onready var canvas = %CanvasLayer

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

func toggle_bg(enabled: bool) -> void:
	get_tree().root.transparent_bg = enabled
	get_window().transparent = true
	get_window().transparent_bg = true
	%Bg.visible = not enabled
	
func _reorder():
	var sorted = canvas.get_children().duplicate()
	sorted.sort_custom(_item_sorter)
	for i in range(len(sorted)):
		sorted[i].z_index = 1000 * i
		canvas.move_child(sorted[i], i)
	update_order.emit(sorted)

func spawn_model(model: VtModel):
	if active_model != null:
		preferences.save_data.call_deferred()
		var t = create_tween().tween_property(
			active_model, "position", Vector2(0, (active_model.size.y * active_model.scale.y) + active_model.get_viewport_rect().size.y), 0.5
		).as_relative().set_trans(Tween.TRANS_CUBIC)
		await t.finished
		canvas.remove_child(active_model)
		active_model.queue_free()
		
	active_model = model
	canvas.add_child(model)
	_reorder()
	await active_model.initialized
	
	# TODO if model had items pinned to it, load them in as well
	model_changed.emit(active_model)

func spawn_item(item: VtItem):
	item.position = get_viewport().get_texture().get_size() / 2
	
	# simply setting z_index does not work for control nodes, as Input order is not affected by it
	# instead we'll rely on child order in the stage to define the 
	canvas.add_child(item)
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
	
	toggle_bg(data.get("window", {}).get("transparent", false))
	
func save_settings(data):
	if active_model != null and active_model.model != null:
		data["active_model"] = active_model.model.id
	
	var window_settings = data.get("window", {})
	window_settings["transparent"] = %Bg.visible
	data["window"] = window_settings
	
