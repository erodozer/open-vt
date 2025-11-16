extends PanelContainer

const VtItem = preload("res://lib/items/vt_item.gd")
const VtModel = preload("res://lib/model/vt_model.gd")
const Stage = preload("res://studio/stage/stage.gd")

@onready var stage: Stage = get_tree().get_first_node_in_group("system:stage")

func _ready():
	if stage:
		stage.model_changed.connect(_on_stage_model_changed)
		stage.item_added.connect(_on_stage_item_added)
		stage.item_removed.connect(_on_stage_item_removed)

func _on_directory_button_pressed() -> void:
	OS.shell_open(ProjectSettings.globalize_path(ItemManager.FILE_DIR))
	
func _on_spawn_btn_pressed() -> void:
	stage.spawn_item(%ItemPopup.item)
	
func _on_stage_item_added(item: VtItem) -> void:
	var row = preload("./item_row.tscn").instantiate()
	row.item = item
	row.model = stage.active_model
	
	%StageItems.add_child(row)

func _on_stage_item_removed(item: VtItem) -> void:
	for i in %StageItems.get_children():
		if i.item == item:
			i.queue_free()

func _on_stage_model_changed(model: VtModel) -> void:
	for i in %StageItems.get_children():
		if i.item != null and i.item is VtModel:
			i.queue_free()

	var row = preload("./item_row.tscn").instantiate()
	row.item = model
	
	%StageItems.add_child(row)

func _on_stage_update_order(objects: Array[Node]) -> void:
	for i in range(len(objects)):
		var o = objects[i]
		for c in %StageItems.get_children():
			if c.item == o:
				%StageItems.move_child(c, i)

func _on_add_button_pressed() -> void:
	if stage.active_model:
		%ItemSelectPopup.show()
	
func _on_clear_button_pressed() -> void:
	stage.clear_items()
