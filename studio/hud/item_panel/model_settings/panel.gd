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
	
	# mesh modifier controls
	var categories = {}
	for property in model.get_property_list():
		if not property.name.begins_with("modifiers/"):
			continue
		var segments = property.name.trim_prefix("modifiers/").split("/")
		var category: String = segments[0]
		var part: String = segments[1]
		var field: String = segments[2]
		
		if category not in categories:
			var panel = preload("./modifier_settings.tscn").instantiate()
			panel.name = "%s Settings" % category.capitalize()
			%Accordion.add_child(panel)
			categories[category] = panel.get_node("%Items")
			
		var list = categories[category]
		if not list.has_node(part):
			var frame = PanelContainer.new()
			frame.name = part
			frame.theme_type_variation = "Section"
			var box = VBoxContainer.new()
			box.name = "Properties"
			var label = Label.new()
			label.text = part
			label.theme_type_variation = "BoldLabel"
		
			box.add_child(label)
			frame.add_child(box)
			list.add_child(frame)
		
		var fields = list.get_node("%s/Properties" % part)
		var f = HBoxContainer.new()
		var label = Label.new()
		label.text = field.replace("_", " ").capitalize()
		label.clip_text = true
		label.theme_type_variation = "FieldLabel"
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		f.add_child(label)
		match property.type:
			Variant.Type.TYPE_FLOAT:
				var range: PackedStringArray = property.hint_string.split(",")
				var control = SpinBox.new()
				control.alignment = HORIZONTAL_ALIGNMENT_RIGHT
				control.min_value = range[0].to_float()
				control.max_value = range[1].to_float()
				control.value = model.get(property.name)
				control.step = 0.01
				control.name = field
				control.value_changed.connect(
					func (v):
						model.set(property.name, v)
				)
				f.add_child(control)
			Variant.Type.TYPE_COLOR:
				var control = ColorPickerButton.new()
				control.custom_minimum_size = Vector2i(48, 0)
				control.color = model.get(property.name)
				control.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
				control.color_changed.connect(
					func (c):
						model.set(property.name, c)
				)
				f.add_child(control)
			Variant.Type.TYPE_BOOL:
				var control = CheckBox.new()
				control.custom_minimum_size = Vector2i(48, 0)
				control.set_pressed_no_signal(model.get(property.name))
				control.size_flags_horizontal = Control.SIZE_SHRINK_END
				control.toggled.connect(
					func (t):
						model.set(property.name, t)
				)
				f.add_child(control)
			_:
				continue
		fields.add_child(f)
			
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
