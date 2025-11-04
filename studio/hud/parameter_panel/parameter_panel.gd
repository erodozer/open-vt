extends "res://ui/popout_panel.gd"

const VtModel = preload("res://lib/model/vt_model.gd")
const Stage = preload("res://studio/stage/stage.gd")

@onready var meshes = get_node("%MeshItems")
var model

func _ready():
	var stage = get_tree().get_first_node_in_group("system:stage")
	if stage:
		stage.model_changed.connect(_on_stage_model_changed)
		model = stage.active_model
		
	%Movement/XValue.value_changed.connect(
		func (value):
			if model:
				model.movement_scale.x = value
	)
	%Movement/YValue.value_changed.connect(
		func (value):
			if model:
				model.movement_scale.y = value
	)
	%Movement/ZValue.value_changed.connect(
		func (value):
			if model:
				model.movement_scale.z = value
	)

func _on_stage_model_changed(model: VtModel) -> void:
	for c in meshes.get_children():
		c.queue_free()
	
	for mesh in model.get_meshes():
		var control = preload("./mesh_setting.tscn").instantiate()
		control.model = model
		control.mesh = mesh as Node
		control.name = mesh.name
		meshes.add_child(control)
	# _model.renderer.transform_updated.connect(_update_transform)
		
	%IdleAnimation.clear()
	%IdleAnimation.add_item("None")
	for anim in model.get_idle_animation_player().get_animation_library("").get_animation_list():
		if anim == "RESET":
			continue
		%IdleAnimation.add_item(anim)
		if anim == model.get_idle_animation_player().current_animation:
			%IdleAnimation.selected = %IdleAnimation.item_count - 1
		
	_update_transform(model.position, model.scale, model.rotation)
	%TextureFilter.select(1 if model.filter == TEXTURE_FILTER_LINEAR else 0)
	%SmoothScaling.set_pressed_no_signal(model.smoothing)
	%GenerateMipmaps.set_pressed_no_signal(model.mipmaps)
	%SmoothScaling.disabled = model.filter == TEXTURE_FILTER_LINEAR
	%GenerateMipmaps.disabled = model.filter != TEXTURE_FILTER_LINEAR
	
	self.model = model
	model.transform_updated.connect(_update_transform)
	
	%Movement/XValue.set_value_no_signal(model.movement_scale.x)
	%Movement/YValue.set_value_no_signal(model.movement_scale.y)
	%Movement/ZValue.set_value_no_signal(model.movement_scale.z)
	
func _update_transform(pos, scl, rot):
	%Position/XValue.min_value = int(-get_viewport_rect().size.x)
	%Position/XValue.max_value = int(get_viewport_rect().size.x * 2)
	%Position/YValue.min_value = int(-get_viewport_rect().size.y)
	%Position/YValue.max_value = int(get_viewport_rect().size.y * 2)
	
	%Position/XValue.set_value_no_signal(pos.x)
	%Position/YValue.set_value_no_signal(pos.y)
	%Scale/Value.set_value_no_signal(scl.x * 100.0)
	%Rotation/Value.set_value_no_signal(rot)
	
func _on_texture_filter_item_selected(index: int) -> void:
	match index:
		0:
			model.filter = CanvasItem.TextureFilter.TEXTURE_FILTER_NEAREST
			%SmoothScaling.disabled = false
			%GenerateMipmaps.disabled = true
		_:
			model.filter = CanvasItem.TextureFilter.TEXTURE_FILTER_LINEAR
			%SmoothScaling.disabled = true
			%GenerateMipmaps.disabled = false

func _on_erase_position_pressed() -> void:
	model.position = get_viewport_rect().get_center()
	_update_transform(model.position, model.scale, model.rotation)
	
func _on_erase_scale_pressed() -> void:
	model.scale = Vector2.ONE * min(1.0, get_viewport_rect().size.y / model.size.y)
	_update_transform(model.position, model.scale, model.rotation)

func _on_erase_rotate_pressed() -> void:
	model.rotation = 0
	_update_transform(model.position, model.scale, model.rotation)

func _on_lock_button_toggled(toggled_on: bool) -> void:
	if model == null:
		return
	model.locked = toggled_on
	
	%Position/XValue.editable = !toggled_on
	%Position/YValue.editable = !toggled_on
	%Scale/Value.editable = !toggled_on
	%Rotation/Value.editable = !toggled_on

func _on_smooth_scaling_toggled(toggled_on: bool) -> void:
	if model == null:
		return
	model.smoothing = toggled_on

func _on_generate_mipmaps_toggled(toggled_on: bool) -> void:
	if model == null:
		return
	model.mipmaps = toggled_on

func _on_idle_animation_item_selected(index: int) -> void:
	if model == null:
		return
	if index <= 0:
		model.get_idle_animation_player().stop()
		model.get_idle_animation_player().play("RESET")
		
	var anim = %IdleAnimation.get_item_text(index)
	model.get_idle_animation_player().play(anim)

func _on_movement_lock_button_toggled(toggled_on: bool) -> void:
	if model == null:
		return
	model.movement_enabled = !toggled_on
	
	%Movement/XValue.editable = !toggled_on
	%Movement/YValue.editable = !toggled_on
	%Movement/ZValue.editable = !toggled_on

func _on_mesh_filter_input_text_changed(new_text: String) -> void:
	var search = new_text.strip_edges()
	for i in meshes.get_children():
		i.visible = i.name.contains(search) or search.is_empty()
