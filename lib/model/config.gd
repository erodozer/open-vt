extends RefCounted

class PartSetting:
	var modulation: Color
	var part_id: String
	var pin_enabled: bool
	
class ParameterBinding:
	var input: String
	var input_range: Vector2
	var input_clamp: bool
	var output: String
	var output_range: Vector2
	var output_clamp: bool

var display_name: String
var icon: String
var parameter_bindings: Array
var input_bindings: Array
var motion_enabled: bool
var motion_scale: Vector3
var part_settings: Array[PartSetting]

static func from_vts(file: String):
	return
