# System for loading models from VTubeStudio's format
# and spawning them into the scene to be managed
extends Node2D

const utils = preload("res://lib/utils.gd")
const ParameterSetting = preload("res://lib/tracking/parameter_setting.gd")
const TrackingSystem = preload("res://lib/tracking_system.gd")
const Draggable = preload("res://lib/draggable.gd")
const ModelMeta = preload("./metadata.gd")
const ModelExpression = preload("res://lib/model/expression.gd")
const HotkeyBinding = preload("res://lib/hotkey/binding.gd")

@onready var drag: Draggable = %Model
@onready var live2d_model = %GDCubismUserModel
var model: ModelMeta

var parameters_l2d: Array
var model_parameters: Dictionary

var filter: CanvasItem.TextureFilter :
	set(v):
		filter = v
		live2d_model.texture_filter = filter
		if filter == CanvasItem.TextureFilter.TEXTURE_FILTER_NEAREST:
			live2d_model.shader_add = preload("res://addons/gd_cubism/res/nearest_shader/2d_cubism_norm_add.gdshader")
			live2d_model.shader_mix = preload("res://addons/gd_cubism/res/nearest_shader/2d_cubism_norm_mix.gdshader")
			live2d_model.shader_mul = preload("res://addons/gd_cubism/res/nearest_shader/2d_cubism_norm_mul.gdshader")
		else:
			live2d_model.shader_add = preload("res://addons/gd_cubism/res/shader/2d_cubism_norm_add.gdshader")
			live2d_model.shader_mix = preload("res://addons/gd_cubism/res/shader/2d_cubism_norm_mix.gdshader")
			live2d_model.shader_mul = preload("res://addons/gd_cubism/res/shader/2d_cubism_norm_mul.gdshader")
			
var studio_parameters: Array = []
var parameter_values: Dictionary = {}
		
var hotkeys: Array :
	get():
		return %HotKeys.get_children()
		
var motions: Dictionary = {}
var expressions: Dictionary = {}
var active_expressions: Dictionary = {}

func is_bound(parameter: GDCubismParameter) -> bool:
	return has_node(parameter.id)

func _ready():
	var placeholder = live2d_model
	
	live2d_model = GDCubismUserModel.new()
	live2d_model.load_expressions = true
	live2d_model.load_motions = true
	live2d_model.assets = model.model
	live2d_model.name = "GDCubismUserModel"
	placeholder.replace_by(live2d_model)
	placeholder.queue_free()
	
	var canvas_info = live2d_model.get_canvas_info()
	# drag.size = live2d_model.get_canvas_info().size_in_pixels
	%Model.position = -live2d_model.get_canvas_info().origin_in_pixels
	%Model.texture = live2d_model.get_texture()
	
	var vtube_data = JSON.parse_string(FileAccess.get_file_as_string(model.studio_parameters))
	var model_data = JSON.parse_string(FileAccess.get_file_as_string(model.model))
	var display_data = JSON.parse_string(FileAccess.get_file_as_string(model.model_parameters))
	
	var output_parameters = display_data["Parameters"]
	for i in live2d_model.get_parameters():
		model_parameters[i.id] = i
		parameter_values[i.id] = i.default_value
		
	var tracking: TrackingSystem = get_tree().get_first_node_in_group("system:tracking")
	tracking.parameters_updated.connect(parameters_updated)

	for parameter_data in vtube_data["ParameterSettings"]:
		var p = preload("res://lib/tracking/parameter_setting.gd").new()
		var ok = p.deserialize(parameter_data)
		if ok:
			p.model_parameter = model_parameters[p.output_parameter]
			studio_parameters.append(p)
			
	var transform = vtube_data.get("SavedModelPosition", {})
	position = utils.vts_to_world(Vector2(transform.get("Position", {}).get("x", 0.0), transform.get("Position", {}).get("y", 0.0)))
	scale = Vector2(transform.get("Scale", {}).get("x", 0.0), transform.get("Scale", {}).get("y", 0.0))
	rotation = transform.get("Rotation", {}).get("z", 0.0)
	
	for hotkey in vtube_data.get("Hotkeys", []):
		var binding = HotkeyBinding.new()

		match hotkey.Action:
			"ToggleExpression":
				binding.action = HotkeyBinding.Action.TOGGLE_EXPRESSION
				binding.file = hotkey.File
			_:
				continue

		binding.name = hotkey.Name
		binding.button_1 = hotkey.Triggers.Trigger1
		binding.button_2 = hotkey.Triggers.Trigger2
		binding.button_3 = hotkey.Triggers.Trigger3
		binding.screen_button = hotkey.Triggers.ScreenButton
		binding.screen_button_color = Color(
			hotkey.OnScreenHotkeyColor.r,
			hotkey.OnScreenHotkeyColor.g,
			hotkey.OnScreenHotkeyColor.b,
			hotkey.OnScreenHotkeyColor.a
		)
		binding.duration = hotkey.FadeSecondsAmount
		binding.deactivate_on_keyup = hotkey.DeactivateAfterKeyUp
		binding.activate.connect(self.activate_hotkey.bind(binding))
		binding.deactivate.connect(self.deactivate_hotkey.bind(binding))
		%HotKeys.add_child(binding)
	
	for e in model.expressions:
		expressions[e.name] = e;
		active_expressions[e] = false
	
	await get_tree().process_frame
	
func add_parameter():
	var p = preload("res://lib/tracking/parameter_setting.gd").new()
	%Parameters.add_child(p)

func activate_hotkey(binding: HotkeyBinding):
	if binding.action == HotkeyBinding.Action.TOGGLE_EXPRESSION:
		var exp = expressions[binding.file]
		toggle_expression(exp, true, binding.duration)

func deactivate_hotkey(binding: HotkeyBinding):
	if binding.action == HotkeyBinding.Action.TOGGLE_EXPRESSION:
		var exp = expressions[binding.file]
		toggle_expression(exp, false, binding.duration)

func toggle_expression(expression: ModelExpression, activate: bool = true, duration: float = 1.0):
	if active_expressions[expression] == activate:
		return
	
	if activate:
		print("applying expression: %s" % expression.name)
	else:
		print("removing expression: %s" % expression.name)
	
	active_expressions[expression] = activate
	
	var t = create_tween()
	for id in expression.parameters:
		var mut = expression.parameters[id]
		var pt = t.parallel().tween_property(
			self, "parameter_values:%s" % id, mut.value if activate else -mut.value, duration
		)
		if mut.blend == ModelExpression.BlendMode.ADD:
			pt.from_current()
	
func parameters_updated(tracking_data: Dictionary):
	for parameter in studio_parameters:
		# skip paramters that haven't been fully configured
		if parameter.output_parameter == null or parameter.model_parameter == null:
			return
		# skip parameters that we do not yet support binding to
		if parameter.input_parameter in tracking_data:
			var raw_value = tracking_data[parameter.input_parameter]
			parameter_values[parameter.model_parameter] = parameter.scale_value(raw_value)

func _process(delta: float) -> void:
	for id in model_parameters.keys():
		model_parameters[id].value = parameter_values[id]
	
