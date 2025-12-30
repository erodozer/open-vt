extends "res://studio/hud/side_panel.gd"

const VtObject = preload("res://lib/vtobject.gd")
const VtItem = preload("res://lib/items/vt_item.gd")
const VtModel = preload("res://lib/model/vt_model.gd")
const Stage = preload("res://studio/stage/stage.gd")

@onready var stage: Stage = get_tree().get_first_node_in_group("system:stage")

func _ready():
	stage.model_changed.connect(_on_stage_model_changed)
	stage.item_added.connect(_on_stage_item_added)
	stage.item_removed.connect(_on_stage_item_removed)

func _on_directory_button_pressed() -> void:
	OS.shell_open(ProjectSettings.globalize_path(ItemManager.FILE_DIR))
	
func setup():
	for i in stage.objects:
		_on_stage_item_added(i)
	
func teardown():
	for i in %StageItems.get_children():
		i.queue_free()
	
func _on_stage_item_added(item: VtObject) -> void:
	if not visible:
		return
	
	var row = preload("./item_row.tscn").instantiate()
	row.item = item
	row.model = stage.active_model
	
	%StageItems.add_child(row)

func _on_stage_item_removed(item: VtItem) -> void:
	if not visible:
		return
	
	for i in %StageItems.get_children():
		if i.item == item:
			i.queue_free()

func _on_stage_model_changed(model: VtModel) -> void:
	if not visible:
		return
	
	for i in %StageItems.get_children():
		if i.item != null and i.item is VtModel:
			i.queue_free()

	_on_stage_item_added(model)

func _on_stage_update_order(objects: Array[Node]) -> void:
	if not visible:
		return
	
	for i in range(len(objects)):
		var o = objects[i]
		for c in %StageItems.get_children():
			if c.item == o:
				%StageItems.move_child(c, i)

func _on_add_button_pressed() -> void:
	if not stage.active_model:
		return
	
	var popup = preload("./item_selector/item_selector.tscn").instantiate()
	add_child(popup)
	
func _on_clear_button_pressed() -> void:
	stage.clear_items()

func _on_load_button_pressed() -> void:
	var popup = preload("./scene_selector/scene_selector_popup.tscn").instantiate()
	add_child(popup)
