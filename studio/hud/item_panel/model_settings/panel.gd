extends Window

const Collections = preload("res://lib/utils/collections.gd")
const VtModel = preload("res://lib/model/vt_model.gd")
const Stage = preload("res://studio/stage/stage.gd")

@onready var stage = get_tree().get_first_node_in_group("system:stage")
var model: VtModel

var _pause_signals = false

func _ready():
	assert(model != null)
	title = "Model Settings [%s]" % model.display_name
	
	# mesh modifier controls
	var categories: Dictionary[String, Node] = {}
	for property in model.get_property_list():
		if not property.name.begins_with("modifiers/"):
			continue
		var segments = property.name.trim_prefix("modifiers/").split("/")
		
		var is_nested = len(segments) == 3
		var category: String = segments[0]
		var field: String
		
		if category not in categories:
			var panel = preload("./modifier_settings.tscn").instantiate()
			panel.name = "%s Settings" % category.capitalize()
			%Accordion.add_child(panel)
			categories[category] = panel.get_node("%Items")
			
		var list = categories[category]
		var fields
		list.set_meta("has_nesting", list.get_meta("has_nesting", false) || is_nested)
		if is_nested:
			var part: String = segments[1]
			field = segments[2]
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
		
			fields = list.get_node("%s/Properties" % part)
		else:
			fields = list
			field = segments[1]
		
		var f = HBoxContainer.new()
		var label = Label.new()
		label.text = field.replace("_", " ").capitalize()
		label.clip_text = true
		if is_nested:
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
				if property.usage & PROPERTY_USAGE_READ_ONLY:
					control.editable = false
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
				if property.usage & PROPERTY_USAGE_READ_ONLY:
					control.disabled = true
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
				if property.usage & PROPERTY_USAGE_READ_ONLY:
					control.disabled = true
				f.add_child(control)
			Variant.Type.TYPE_STRING,Variant.Type.TYPE_STRING_NAME:
				var control
				# enum
				if "," in property.hint_string:
					control = OptionButton.new()
					var idx = 0
					for choice in property.hint_string.split(","):
						control.add_item(choice)
						if model.get(property.name) == choice:
							control.select(idx)
						idx += 1
					control.alignment = HORIZONTAL_ALIGNMENT_RIGHT
					control.item_selected.connect(
						func (idx):
							model.set(property.name, control.get_item_text(idx))
					)
					if property.usage & PROPERTY_USAGE_READ_ONLY:
						control.disabled = true
				else:
					control = LineEdit.new()
					control.alignment = HORIZONTAL_ALIGNMENT_RIGHT
					control.text = model.get(property.name)
					control.text_changed.connect(
						func (text):
							model.set(property.name, text)
					)
					if property.usage & PROPERTY_USAGE_READ_ONLY:
						control.editable = false
				control.custom_minimum_size = Vector2i(150, 0)
				control.size_flags_horizontal = Control.SIZE_SHRINK_END
				f.add_child(control)
			_:
				continue
		fields.add_child(f)
	
	# _model.renderer.transform_updated.connect(_update_transform)
		
	#%SmoothScaling.set_pressed_no_signal(model.smoothing)
	#%GenerateMipmaps.set_pressed_no_signal(model.mipmaps)
	#%SmoothScaling.disabled = model.filter == TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	#%GenerateMipmaps.disabled = model.filter != TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	
	var expression_controller = model.get_expression_controller()
	if expression_controller:
		for expression in expression_controller.expressions:
			var name = expression.get_name()
			var row = HBoxContainer.new()
			var label = Label.new()
			label.text = name
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(label)
			
			var edit = LineEdit.new()
			edit.text = ",".join(expression_controller.get("expression_groups/%s" % name))
			edit.editing_toggled.connect(
				func (_mode):
					var text = edit.text
					var groups: Array = Array(text.split(","))\
						.map(func (v: String): return StringName(v.strip_edges()))\
						.filter(func (v: String): return not v.is_empty())
					expression_controller.set("expression_groups/%s" % name, groups)
					var update = expression_controller.get("expression_groups/%s" % name)
					assert(update == groups, "unable to insert groups")
			)
			edit.custom_minimum_size = Vector2i(180, 0)
			edit.size_flags_horizontal = Control.SIZE_SHRINK_END
			row.add_child(edit)
			%ExpressionList.add_child(row)
	else:
		%"Expression Settings".queue_free()
	
	model.request_delete.connect(close_requested.emit)

func _on_idle_animation_item_selected(index: int) -> void:
	if index <= 0:
		model.get_idle_animation_player().stop()
		model.get_idle_animation_player().play("RESET")
		
	var anim = %IdleAnimation.get_item_text(index)
	model.get_idle_animation_player().play(anim)

func _on_close_requested() -> void:
	model.save_settings({})
	queue_free()
