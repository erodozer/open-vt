extends "res://lib/popout_panel.gd"

const VtModel = preload("res://lib/model/vt_model.gd")
const TrackingInput = preload("res://lib/tracking/tracker.gd").Inputs
const ParameterSetting = preload("res://lib/tracking/parameter_setting.gd")
const Stage = preload("res://lib/stage.gd")

@onready var list = get_node("%ParameterList")
@onready var meshes = get_node("%Mesh Settings")
@onready var model = get_tree().get_first_node_in_group("vtmodel")

signal parameter_selected(value)

func _ready():
	_build_input_parameter_list()
	var stage = get_tree().get_first_node_in_group("system:stage")
	if stage:
		stage.model_changed.connect(_on_stage_model_changed)

func _on_stage_model_changed(model) -> void:
	for c in list.get_children():
		c.queue_free()
	for c in meshes.get_children():
		c.queue_free()
		
	for parameter_data in model.studio_parameters:
		var control = preload("./parameter_setting.tscn").instantiate()
		control.parameter = parameter_data
		control.model_parameters = model.parameters_l2d
		control.get_node("%InputSelect").pressed.connect(_popup_input_select.bind(parameter_data))
		control.get_node("%OutputSelect").pressed.connect(_popup_output_select.bind(parameter_data))
		list.add_child(control)
		
	for mesh in model.get_meshes():
		var control = preload("./mesh_setting.tscn").instantiate()
		control.model = model
		control.mesh = mesh
		meshes.add_child(control)
	# _model.renderer.transform_updated.connect(_update_transform)
		
	_build_output_parameter_list(model)
	_update_transform(model.position, model.scale, model.rotation)
	
	self.model = model
	model.transform_updated.connect(_update_transform)
	
func _update_transform(pos, scl, rot):
	%Position/XValue.min_value = int(-get_viewport_rect().size.x)
	%Position/XValue.max_value = int(get_viewport_rect().size.x * 2)
	%Position/YValue.min_value = int(-get_viewport_rect().size.y)
	%Position/YValue.max_value = int(get_viewport_rect().size.y * 2)
	
	%Position/XValue.set_value_no_signal(pos.x)
	%Position/YValue.set_value_no_signal(pos.y)
	%Scale/Value.set_value_no_signal(scl.x * 100.0)
	%Rotation/Value.set_value_no_signal(rot)
			
func _build_input_parameter_list():
	for c in %InputParameterList.get_children():
		c.queue_free()

	for parameter in TrackingInput:
		var btn = Button.new()
		btn.name = parameter
		btn.text = parameter
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(parameter_selected.emit.bind(TrackingInput[parameter]))
		%InputParameterList.add_child(btn)
		
func _build_output_parameter_list(_model: VtModel):
	for c in %OutputParameterList.get_children():
		c.queue_free()
		
	for parameter in _model.parameters_l2d:
		var btn = Button.new()
		btn.name = parameter.id
		btn.text = parameter.id
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.disabled = _model.studio_parameters.any(
			func (p):
				return p.output_parameter == parameter.id
		)
		btn.pressed.connect(parameter_selected.emit.bind(parameter))
		%OutputParameterList.add_child(btn)
		
	var btn = Button.new()
	btn.name = "unset"
	btn.text = "-"
	btn.pressed.connect(parameter_selected.emit.bind(null))
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	%OutputParameterList.add_child(btn)
	%OutputParameterList.move_child(btn, 0)

func _popup_output_select(parameter: ParameterSetting):
	%Modal.show()
	%OutputParameterPopup.set_meta("previous_value", parameter.output_parameter)
	%OutputParameterPopup.show()
	
	var model_parameter = await parameter_selected
	
	%OutputParameterPopup.hide()
	%Modal.hide()
	
	if parameter.output_parameter != null:
		%OutputParameterList.get_node(parameter.output_parameter).disabled = false
	
	if model_parameter == null:
		parameter.model_parameter = null
	else:
		parameter.model_parameter = model_parameter
		%OutputParameterList.get_node(parameter.output_parameter).disabled = true

func _popup_input_select(parameter: ParameterSetting):
	%Modal.show()
	%InputParameterPopup.set_meta("previous_value", parameter.input_parameter)
	%InputParameterPopup.show()
	
	var input_parameter = await parameter_selected
	
	%InputParameterPopup.hide()
	%Modal.hide()
	
	if input_parameter == null:
		return
	
	parameter.input_parameter = input_parameter

func _on_tracker_system_parameters_updated(parameters: Dictionary) -> void:
	if !is_node_ready():
		return
	for p in list.get_children():
		if p.parameter == null:
			continue
		var input = parameters.get(p.parameter.input_parameter, 0)
		var output = p.parameter.scale_value(input)
		p.get_node("%InputLevel").value = input
		
func _process(delta: float) -> void:
	for p in list.get_children():
		if p.parameter.model_parameter == null:
			continue
		p.get_node("%OutputLevel").value = p.parameter.model_parameter.value

func _on_texture_filter_item_selected(index: int) -> void:
	match index:
		0:
			model.filter = CanvasItem.TextureFilter.TEXTURE_FILTER_NEAREST
			%SmoothScaling.show()
		_:
			model.filter = CanvasItem.TextureFilter.TEXTURE_FILTER_LINEAR
			%SmoothScaling.hide()

func _on_erase_position_pressed() -> void:
	model.position = get_viewport_rect().get_center() - model.size / 2
	_update_transform(model.position, model.scale, model.rotation)
	
func _on_erase_scale_pressed() -> void:
	model.scale = Vector2.ONE
	_update_transform(model.position, model.scale, model.rotation)

func _on_erase_rotate_pressed() -> void:
	model.rotation = 0
	_update_transform(model.position, model.scale, model.rotation)

func _on_input_parameter_popup_close_requested() -> void:
	var prev = %InputParameterPopup.get_meta("previous_value", null)
	parameter_selected.emit(prev)

func _on_output_parameter_popup_close_requested() -> void:
	var prev = %OutputParameterPopup.get_meta("previous_value", null)
	parameter_selected.emit(prev)

func _on_lock_button_toggled(toggled_on: bool) -> void:
	model.locked = toggled_on
	
	%Position/XValue.editable = !toggled_on
	%Position/YValue.editable = !toggled_on
	%Scale/Value.editable = !toggled_on
	%Rotation/Value.editable = !toggled_on

func _on_smooth_scaling_toggled(toggled_on: bool) -> void:
	model.smoothing = toggled_on
