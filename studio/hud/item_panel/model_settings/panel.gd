extends Window

const Collections = preload("res://lib/utils/collections.gd")
const VtModel = preload("res://lib/model/vt_model.gd")
const Stage = preload("res://studio/stage/stage.gd")

@onready var stage = get_tree().get_first_node_in_group("system:stage")
@onready var meshes = %MeshItems
var model: VtModel

var _pause_signals = false

func _ready():
	assert(model != null)
	%Movement/XValue.value_changed.connect(_move_model)
	%Movement/YValue.value_changed.connect(_move_model)
	%Movement/ZValue.value_changed.connect(_move_model)
	%Movement/LockButton.toggled.connect(_on_movement_lock_button_toggled)

	for mesh in model.get_meshes():
		var control = preload("./mesh_setting.tscn").instantiate()
		control.model = model
		control.mesh = mesh as Node
		control.name = mesh.name
		meshes.add_child(control)
		
	for part in Collections.select(model.get_property_list(), "name", RegEx.create_from_string("^parts/")):
		var control = preload("./part_setting.tscn").instantiate()
		var part_name = part.name.trim_prefix("parts/")
		control.model = model
		control.part = part_name
		control.name = part_name
		%PartItems.add_child(control)
		
	# _model.renderer.transform_updated.connect(_update_transform)
		
	%IdleAnimation.clear()
	%IdleAnimation.add_item("None")
	var lib = model.get_idle_animation_player().get_animation_library("")
	if lib:
		for anim in lib.get_animation_list():
			if anim == "RESET":
				continue
			%IdleAnimation.add_item(anim)
			if anim == model.get_idle_animation_player().current_animation:
				%IdleAnimation.selected = %IdleAnimation.item_count - 1
	%IdleAnimation.disabled = not lib or lib.get_animation_list_size() == 0
		
	%TextureFilter.select(1 if model.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC else 0)
	#%SmoothScaling.set_pressed_no_signal(model.smoothing)
	#%GenerateMipmaps.set_pressed_no_signal(model.mipmaps)
	#%SmoothScaling.disabled = model.filter == TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	#%GenerateMipmaps.disabled = model.filter != TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	
	%Movement/XValue.set_value_no_signal(model.movement_scale.x)
	%Movement/YValue.set_value_no_signal(model.movement_scale.y)
	%Movement/ZValue.set_value_no_signal(model.movement_scale.z)
	
	model.request_delete.connect(close_requested.emit)
	
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
			model.texture_filter = CanvasItem.TextureFilter.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS_ANISOTROPIC
			%SmoothScaling.disabled = false
		_:
			model.texture_filter = CanvasItem.TextureFilter.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			%SmoothScaling.disabled = true

func _on_smooth_scaling_toggled(toggled_on: bool) -> void:
	model.smoothing = toggled_on

func _on_idle_animation_item_selected(index: int) -> void:
	if index <= 0:
		model.get_idle_animation_player().stop()
		model.get_idle_animation_player().play("RESET")
		
	var anim = %IdleAnimation.get_item_text(index)
	model.get_idle_animation_player().play(anim)

func _on_movement_lock_button_toggled(toggled_on: bool) -> void:
	model.movement_enabled = !toggled_on
	
	%Movement/XValue.editable = !toggled_on
	%Movement/YValue.editable = !toggled_on
	%Movement/ZValue.editable = !toggled_on

func _on_close_requested() -> void:
	queue_free()
