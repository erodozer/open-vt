# System for loading models from VTubeStudio's format
# and spawning them into the scene to be managed
extends "res://lib/vtobject.gd"

const utils = preload("res://lib/utils.gd")
const ParameterSetting = preload("res://lib/tracking/parameter_setting.gd")
const TrackingSystem = preload("res://lib/tracking_system.gd")
const ModelMeta = preload("./metadata.gd")
const ModelExpression = preload("res://lib/model/expression.gd")
const HotkeyBinding = preload("res://lib/hotkey/binding.gd")

@onready var live2d_model = %GDCubismUserModel
var model: ModelMeta
var motions: AnimationLibrary

var parameters_l2d: Array
var model_parameters: Dictionary

var filter: CanvasItem.TextureFilter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS :
	set(v):
		filter = v
		update_shaders()
		_rebuild_l2d(model)
			
var studio_parameters: Array = []
var parameter_values: Dictionary = {}
		
var hotkeys: Array :
	get():
		return %HotKeys.get_children()
		
var expressions: Dictionary = {}
var active_expressions: Dictionary = {}

# item pinning
var pinnable: Dictionary = {}
var rest_anchors: Dictionary = {}

func get_meshes() -> Array:
	if not live2d_model.assets.is_empty():
		return live2d_model.get_meshes().values()
	return []

func is_bound(parameter: GDCubismParameter) -> bool:
	return has_node(parameter.id)

func _ready():
	if model:
		update_shaders()
		_load_model(model)
	
func _rebuild_l2d(model: ModelMeta):
	live2d_model.assets = model.model
	var canvas_info = live2d_model.get_canvas_info()
	render.size = canvas_info.size_in_pixels
	render.position = -canvas_info.origin_in_pixels
	for m in get_meshes():
		var center = utils.v32xy(utils.centroid(m.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]))
		m.set_meta("centroid", center)
		m.set_meta("start_centroid", center)
		m.set_meta("global_centroid", render.global_position + center)

func _load_model(model: ModelMeta):
	_rebuild_l2d(model)
	
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
	# position = get_viewport().size / 2
	scale = Vector2(transform.get("Scale", {}).get("x", 1.0), transform.get("Scale", {}).get("y", 1.0))
	rotation = transform.get("Rotation", {}).get("z", 0.0)
	
	for e in model.expressions:
		expressions[e.name] = e;
		active_expressions[e] = false
	
	# load motions as godot animations
	var anim_player: AnimationPlayer = %AnimationPlayer
	motions = anim_player.get_animation_library("")
	for motion in utils.walk_files(model.model.get_base_dir(), "motion3.json"):
		var anim = GDCubismMotionImporter.parse_motion(motion)
		motions.add_animation(motion.get_file(), anim)
	# generate reset animation
	var reset = Animation.new()
	for p in live2d_model.get_parameters():
		var t = reset.add_track(Animation.TYPE_VALUE)
		reset.track_set_path(t, ".:%s" % p.id)
		reset.track_insert_key(t, 0, p.value)
	motions.add_animation("RESET", reset)
	
	if len(motions.get_animation_list()) > 0:
		anim_player.play(motions.get_animation_list()[0])
	
	for hotkey in vtube_data.get("Hotkeys", []):
		var binding = HotkeyBinding.new()

		match hotkey.Action:
			"ToggleExpression":
				if hotkey.File not in expressions:
					continue
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
	
	var mesh_details = vtube_data.get("ArtMeshDetails", {})
	for m in get_meshes():
		pinnable[m.name] = m.name not in mesh_details.get("ArtMeshesExcludedFromPinning", [])
		var center = utils.v32xy(utils.centroid(m.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]))
		m.set_meta("centroid", center)
		m.set_meta("start_centroid", center)
		m.set_meta("global_centroid", render.global_position + center)
		
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
			parameter_values[parameter.output_parameter] = parameter.scale_value(raw_value)
			model_parameters[parameter.output_parameter].value = parameter_values[parameter.output_parameter]
		
func update_shaders():
	render.texture_filter = filter
	match filter:
		CanvasItem.TextureFilter.TEXTURE_FILTER_NEAREST, CanvasItem.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS, CanvasItem.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS_ANISOTROPIC:
			live2d_model.shader_add = preload("res://lib/model/shaders/nearest/2d_cubism_norm_add.gdshader")
			live2d_model.shader_mix = preload("res://lib/model/shaders/nearest/2d_cubism_norm_mix.gdshader")
			live2d_model.shader_mul = preload("res://lib/model/shaders/nearest/2d_cubism_norm_mul.gdshader")
		_:
			live2d_model.shader_add = preload("res://addons/gd_cubism/res/shader/2d_cubism_norm_add.gdshader")
			live2d_model.shader_mix = preload("res://lib/model/shaders/linear/2d_cubism_norm_mix.gdshader")
			live2d_model.shader_mul = preload("res://addons/gd_cubism/res/shader/2d_cubism_norm_mul.gdshader")
	for m in get_meshes():
		m.texture_filter = filter

func _process(delta: float) -> void:
	pass
#	for m in get_meshes():
#		var center = utils.v32xy(utils.centroid(m.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]))
#		m.set_meta("centroid", center)
#		m.set_meta("global_centroid", render.global_position + center)
#		m.set_meta("angle", center.angle_to(m.get_meta("start_centroid")))
