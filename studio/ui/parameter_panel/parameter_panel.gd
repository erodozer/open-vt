extends PanelContainer

const VtModel = preload("res://lib/model/vt_model.gd")
const TrackingInput = preload("res://lib/tracking/tracker.gd").Inputs
const ParameterSetting = preload("res://lib/tracking/parameter_setting.gd")

@onready var list = %ParameterList
var model: VtModel

signal parameter_selected(value)

func _ready():
	_build_input_parameter_list()

func _on_model_manager_model_changed(_model: VtModel) -> void:
	for c in list.get_children():
		c.queue_free()

	for parameter_data in _model.parameters:
		var control = preload("./parameter_setting.tscn").instantiate()
		control.parameter = parameter_data
		control.model_parameters = _model.parameters_l2d
		control.get_node("%InputSelect").pressed.connect(_popup_input_select.bind(parameter_data))
		control.get_node("%OutputSelect").pressed.connect(_popup_output_select.bind(parameter_data))
		list.add_child(control)
		
	_build_output_parameter_list(_model)
	
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
		btn.disabled = _model.parameters.any(
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
		
	model = _model

func _popup_output_select(parameter: ParameterSetting):
	%Modal.show()
	%OutputParameterPopup.show()
	
	var model_parameter = await parameter_selected as GDCubismParameter
	
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
	%InputParameterPopup.show()
	
	var input_parameter = await parameter_selected as TrackingInput
	
	%InputParameterPopup.hide()
	%Modal.hide()
	
	parameter.input_parameter = input_parameter

func _on_tracker_system_parameters_updated(parameters: Dictionary) -> void:
	if !is_node_ready():
		return
	for p in list.get_children():
		if p.parameter == null:
			continue
		var input = parameters.get(p.parameter.input_parameter, 0)
		p.get_node("%InputLevel").value = input
		p.get_node("%OutputLevel").value = p.parameter.value(input)

func _on_texture_filter_item_selected(index: int) -> void:
	match index:
		0:
			model.filter = CanvasItem.TextureFilter.TEXTURE_FILTER_NEAREST
		_:
			model.filter = CanvasItem.TextureFilter.TEXTURE_FILTER_LINEAR
