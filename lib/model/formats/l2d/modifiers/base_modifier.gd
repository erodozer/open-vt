extends "res://lib/model/modifier.gd"

@export_enum(
	"Bilinear", "Nearest",
) var filter_mode: String = "Bilinear" :
		set(v):
			filter_mode = v
			var filter = CanvasItem.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS_ANISOTROPIC \
				if v == "Nearest" \
				else CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		
			_model.texture_filter = filter
			_adjust_filter()

@export var smoothing: bool = false :
	set(v):
		smoothing = v
		_adjust_filter()

var _model
func _init(model) -> void:
	_model = model

func _adjust_filter():
	var container = _model.container
	if filter_mode == "Nearest" and smoothing:
		container.model = _model.model
	else:
		_model.model.reparent(_model, false)
		container.model = null

func _get_property_list() -> Array[Dictionary]:
	var anim: AnimationPlayer = _model.get_idle_animation_player()
	var lib = anim.get_animation_list()
	return [
		{
			"name": "idle_animation",
			"type": TYPE_STRING_NAME,
			"hint": PROPERTY_HINT_NONE,
			"hint_string": ",".join(lib),
			"usage": PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR
		}
	]
	
func _set(property: StringName, value: Variant) -> bool:
	if property == "idle_animation":
		if value == "":
			_model.get_idle_animation_player().stop()
		else:
			_model.get_idle_animation_player().play(value)
		return true
	return false
	
func _get(property: StringName) -> Variant:
	if property == "idle_animation":
		return _model.get_idle_animation_player().current_animation
	return null
