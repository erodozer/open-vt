extends Node

const GROUP_NAME = "system:stage"

const Collections = preload("res://lib/utils/collections.gd")
const VtObject = preload("res://lib/vtobject.gd")
const VtModel = preload("res://lib/model/vt_model.gd")
const VtItem = preload("res://lib/items/vt_item.gd")

const INDEX_RANGE = 30

var background_mode: int :
	set(mode):
		var transparent = mode == 3
		%Bg.visible = not transparent
		if is_inside_tree():
			get_tree().root.transparent_bg = transparent
			get_window().transparent = transparent
			get_window().transparent_bg = transparent
		
		%Bg/BackgroundImage.visible = mode == 1
		%Bg/DefaultBackground.visible = mode == 0 or (background_image.is_empty() and mode == 1)
		%Bg/GridFill.visible = mode == 0 or (background_image.is_empty() and mode == 1)
		%Bg/ColorFill.visible = mode == 2
		background_mode = mode

var background_image: String = "" :
	set(path):
		if path.is_empty():
			%Bg/DefaultBackground.visible = true
			%Bg/GridFill.visible = true
			background_image = path
			return

		var image = Image.load_from_file(path)
		if not image:
			return

		var tex = ImageTexture.create_from_image(image)
		%Bg/BackgroundImage.texture = tex
		background_image = path
		
		if background_mode == 1:
			%Bg/DefaultBackground.visible = false
			%Bg/GridFill.visible = false
		
var background_color: Color = Color.BLACK :
	set(color):
		%Bg/ColorFill.color = color
		background_color = color

var active_model: VtModel
@onready var canvas = %ModelLayer
@onready var capture_viewport = %SubViewport

signal model_changed(model: VtModel)
signal item_added(item: VtItem)
signal item_removed(item: VtItem)

var objects: Array :
	get():
		return canvas.get_children()

func _ready() -> void:
	# allow items to be dropped onto the window to spawn instantly
	get_window().files_dropped.connect(
		func (paths):
			var item = await ItemManager.create_item(paths)
			if item:
				spawn_item(item)
	)

func spawn_model(model: VtModel):
	if model == null:
		push_warning("invalid model attempted to load")
		return
	
	var prev_model
	if active_model != null:
		await Preferences.save_data()
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
					remove_item(i, false)
		
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
			# remove an item if it was pinned to the previous model
			if i.pinned_to != null:
				remove_item(i, false)

	# TODO if model had items pinned to it, load them in as well
	model_changed.emit(active_model)
	if prev_model != null:
		prev_model.queue_free()

func spawn_item(item: VtItem, animate = true, reposition = true):
	# do not allow spawning items if there is no active model
	if active_model == null:
		return
		
	# position to center of screen
	if reposition:
		var viewport_rect = get_viewport().get_visible_rect()
		item.model = active_model
		item.scale = Vector2.ONE * min(
			clampf(viewport_rect.size.y / item.size.y, 0.001, 1.0),
			1.0
		)
		item.global_position = (viewport_rect.size / 2) - (item.scale * item.center)
	
	# simply setting z_index does not work for control nodes, as Input order is not affected by it
	# instead we'll rely on child order in the stage to define the position
	if item.get_parent():
		item.reparent(canvas)
	else:
		canvas.add_child(item)
	item_added.emit(item)
	item.request_delete.connect(remove_item.bind(item))
	
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

func remove_item(item: VtItem, animated = true):
	if animated:
		var t = create_tween()
		t.parallel().tween_property(
			item, "scale", item.scale * 0.3, 0.4
		).from(item.scale).set_trans(Tween.TRANS_CIRC)
		#t.parallel().tween_property(
		#	item, "rotation_degrees", 0, 0.4
		#).from(60).set_trans(Tween.TRANS_QUAD)
		t.parallel().tween_property(
			item, "modulate", Color.TRANSPARENT, 0.4
		).from(Color.WHITE).set_ease(Tween.EASE_IN)
		t.finished.connect(item.queue_free)
	else:
		item.queue_free()
	item_removed.emit(item)
	
func clear_items(group_name: StringName = &"*"):
	for i in canvas.get_children():
		if i is VtItem:
			if group_name == &"*" or i.group_name == group_name:
				remove_item(i)

func load_settings(data):
	if "active_model" in data:
		var mm = get_tree().get_first_node_in_group("system:model")
		var model = mm.make_model(data["active_model"])
		if model:
			spawn_model(model)
	
	self.background_image = Collections.path(data, "window.background_image", "")
	self.background_color = Color(Collections.path(data, "window.background_color", "000000"))
	self.background_mode = Collections.path(data, "window.background_mode", 0)
	
func save_settings(data):
	if active_model != null and active_model.modelmeta != null:
		data["active_model"] = active_model.modelmeta.model
	
	var window_settings = data.get("window", {})
	window_settings["transparent"] = %Bg.visible
	window_settings["background_mode"] = background_mode
	window_settings["background_image"] = background_image
	window_settings["background_color"] = background_color.to_html()
	data["window"] = window_settings
	
func _on_model_layer_child_order_changed() -> void:
	for i in canvas.get_children():
		i.sort_order = i.get_index()
