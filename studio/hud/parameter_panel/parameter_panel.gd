extends "res://studio/hud/side_panel.gd"

const VtModel = preload("res://lib/model/vt_model.gd")
const Stage = preload("res://studio/stage/stage.gd")
const PhysicsValueProvider = preload("res://lib/model/formats/l2d/physics_value_provider.gd")

@onready var stage = get_tree().get_first_node_in_group("system:stage")
@onready var meshes = %MeshItems
@onready var physics = %PhysicsItems
var model: VtModel

var _pause_signals = false

func _ready():
	%Movement/XValue.value_changed.connect(_move_model)
	%Movement/YValue.value_changed.connect(_move_model)
	%Movement/ZValue.value_changed.connect(_move_model)
	%Movement/LockButton.toggled.connect(_on_movement_lock_button_toggled)

func teardown():
	model = null
	for c in meshes.get_children():
		c.queue_free()
	for c in physics.get_children():
		c.queue_free()
	
func setup():
	model = stage.active_model
	if model == null:
		return
	
	for mesh in model.get_meshes():
		var control = preload("./mesh_setting.tscn").instantiate()
		control.model = model
		control.mesh = mesh as Node
		control.name = mesh.name
		meshes.add_child(control)
	# _model.renderer.transform_updated.connect(_update_transform)
	
	for physics in model.mixer.get_children():
		if physics is PhysicsValueProvider:
			var setting = preload("./physics_setting.tscn").instantiate()
			setting.provider = physics
			%PhysicsItems.add_child(setting)
			
	%IdleAnimation.clear()
	%IdleAnimation.add_item("None")
	for anim in model.get_idle_animation_player().get_animation_library("").get_animation_list():
		if anim == "RESET":
			continue
		%IdleAnimation.add_item(anim)
		if anim == model.get_idle_animation_player().current_animation:
			%IdleAnimation.selected = %IdleAnimation.item_count - 1
		
	%TextureFilter.select(1 if model.filter == TEXTURE_FILTER_LINEAR_WITH_MIPMAPS else 0)
	%SmoothScaling.set_pressed_no_signal(model.smoothing)
	%GenerateMipmaps.set_pressed_no_signal(model.mipmaps)
	%SmoothScaling.disabled = model.filter == TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	%GenerateMipmaps.disabled = model.filter != TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	
	self.model = model
	
	%Movement/XValue.set_value_no_signal(model.movement_scale.x)
	%Movement/YValue.set_value_no_signal(model.movement_scale.y)
	%Movement/ZValue.set_value_no_signal(model.movement_scale.z)
	
func _move_model(_value):
	if not model:
		return
		
	_pause_signals = true
	model.movement_scale = Vector3(
		%Movement/XValue.value,
		%Movement/YValue.value,
		%Movement/ZValue.value
	)
	_pause_signals = false
	
func _on_texture_filter_item_selected(index: int) -> void:
	match index:
		0:
			model.filter = CanvasItem.TextureFilter.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
			%SmoothScaling.disabled = false
			%GenerateMipmaps.disabled = true
		_:
			model.filter = CanvasItem.TextureFilter.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			%SmoothScaling.disabled = true
			%GenerateMipmaps.disabled = false

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

func _on_search_text_changed(new_text: String) -> void:
	var search = new_text.to_lower().strip_edges()
	for i in meshes.get_children():
		i.visible = i.name.to_lower().contains(search) or search.is_empty()
