extends Node

const GROUP_NAME = "system:stage"

const VtModel = preload("res://lib/model/vt_model.gd")
const VtItem = preload("res://lib/items/vt_item.gd")

const INDEX_RANGE = 30

@onready var preferences = get_tree().get_first_node_in_group("system:settings")
@onready var active_model: VtModel = %VtModel
@onready var canvas = %ModelLayer
@onready var capture_viewport = %SubViewport

signal model_changed(model: VtModel)
signal item_added(item: VtItem)

func toggle_bg(enabled: bool) -> void:
	get_tree().root.transparent_bg = enabled
	get_window().transparent = true
	get_window().transparent_bg = true
	%Bg.visible = not enabled
	
func spawn_model(model: VtModel):
	if model == null:
		push_warning("invalid model attempted to load")
		return
	
	var prev_model
	if active_model != null:
		await preferences.save_data()
		prev_model = active_model
		var t = create_tween().tween_property(
			active_model, "position", Vector2(0, (active_model.size.y * active_model.scale.y) + active_model.get_viewport_rect().size.y), 0.5
		).as_relative().set_trans(Tween.TRANS_CUBIC)
		await t.finished
		# clear all pinned items
		for i in canvas.get_children():
			if i is VtItem:
				i.model = null
				if i.pinned_to != null:
					i.queue_free()
		
		canvas.remove_child.call_deferred(active_model)
		
	model.position = Vector2.INF # initialize offscreen
	canvas.add_child(model)
	
	await model.loaded
	
	if model.is_queued_for_deletion():
		get_tree().get_first_node_in_group("system:alert").alert("Unable to load model")	
		return
	active_model = model
	
	create_tween().tween_property(
		model, "position",
		model.position,
		0.5
	).from(
		model.position + Vector2(0, model.get_viewport_rect().size.y)
	).set_trans(Tween.TRANS_CUBIC)

	# make carried over objects aware of the new model
	for i in canvas.get_children():
		if i is VtItem:
			i.model = model
			if i.pinned_to != null:
				i.queue_free()

	# TODO if model had items pinned to it, load them in as well
	model_changed.emit(active_model)
	if prev_model != null:
		prev_model.queue_free()

func spawn_item(item: VtItem, animate = true):
	# do not allow spawning items if there is no active model
	if active_model == null:
		return
		
	# position to center of screen
	var viewport_rect = get_viewport().get_visible_rect()
	item.model = active_model
	item.scale = Vector2.ONE * min(
		clampf(viewport_rect.size.y / item.size.y, 0.001, 1.0),
		1.0
	)
	item.global_position = (viewport_rect.size / 2) - (item.scale * item.center)
	
	# simply setting z_index does not work for control nodes, as Input order is not affected by it
	# instead we'll rely on child order in the stage to define the position
	canvas.add_child(item)
	item_added.emit(item)
	preferences.save_data.call_deferred()
	
	if not animate:
		return
	
	var t = create_tween()
	t.parallel().tween_property(
		item, "scale", item.scale, 0.4
	).from(Vector2.ONE * 0.3).set_trans(Tween.TRANS_CIRC)
	#t.parallel().tween_property(
	#	item, "rotation_degrees", 0, 0.4
	#).from(60).set_trans(Tween.TRANS_QUAD)
	t.parallel().tween_property(
		item, "modulate", Color.WHITE, 0.4
	).from(Color.TRANSPARENT).set_ease(Tween.EASE_IN)

func remove_item(_item: VtItem):
	pass
	
func clear_items():
	pass

func load_settings(data):
	if "active_model" in data:
		var mm = get_tree().get_first_node_in_group("system:model")
		var model = mm.make_model(data["active_model"])
		if model:
			spawn_model(model)
	
	toggle_bg(data.get("window", {}).get("transparent", false))
	
func save_settings(data):
	if active_model != null and active_model.model != null:
		data["active_model"] = active_model.model.id
	
	var window_settings = data.get("window", {})
	window_settings["transparent"] = %Bg.visible
	data["window"] = window_settings
	
func _on_model_layer_child_order_changed() -> void:
	for i in canvas.get_children():
		i.sort_order = i.get_index()
